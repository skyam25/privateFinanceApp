//
//  SimpleFINService.swift
//  GhostVault
//
//  Service for interacting with SimpleFIN Bridge API
//  See: https://bridge.simplefin.org/info/developers
//

import Foundation
import os.log

// MARK: - SimpleFIN API Service

actor SimpleFINService {
    private let keychainService = KeychainService()
    private let logger = Logger(subsystem: "com.ghostvault.app", category: "SimpleFIN")

    // MARK: - Server Info

    /// Check server's supported protocol versions
    /// GET /info - No authentication required
    func getServerInfo(baseURL: String) async throws -> SimpleFINServerInfo {
        logger.info("Fetching server info from \(baseURL)")

        guard let url = URL(string: "\(baseURL)/info") else {
            logger.error("Invalid base URL for server info")
            throw SimpleFINError.invalidAccessURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type for server info")
            throw SimpleFINError.invalidResponse
        }

        logger.debug("Server info response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            logger.error("Server info failed with status \(httpResponse.statusCode)")
            throw SimpleFINError.invalidResponse
        }

        let serverInfo = try JSONDecoder().decode(SimpleFINServerInfo.self, from: data)
        logger.info("Server supports versions: \(serverInfo.versions.joined(separator: ", "))")
        return serverInfo
    }

    // MARK: - Token Exchange

    /// Exchange a setup token for an access URL
    /// The setup token is base64-encoded and contains the claim URL
    func claimSetupToken(_ setupToken: String) async throws -> String {
        logger.info("Claiming setup token...")

        // Trim whitespace from token (users may copy with trailing newlines)
        let trimmedToken = setupToken.trimmingCharacters(in: .whitespacesAndNewlines)
        logger.debug("Token length after trim: \(trimmedToken.count)")

        // Step 1: Base64 decode the setup token to get the claim URL
        // Handle both standard and URL-safe base64
        guard let tokenData = Data(base64Encoded: trimmedToken) ??
                              Data(base64Encoded: trimmedToken, options: .ignoreUnknownCharacters),
              let claimURL = String(data: tokenData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: claimURL) else {
            logger.error("Failed to decode setup token - invalid base64 or URL format")
            throw SimpleFINError.invalidSetupToken
        }

        logger.debug("Decoded claim URL host: \(url.host ?? "unknown")")

        // Step 2: POST to the claim URL to receive the access URL
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("0", forHTTPHeaderField: "Content-Length")

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Claim request failed - invalid response type")
            throw SimpleFINError.invalidResponse
        }

        logger.info("Claim response status: \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200:
            // Trim whitespace from response (may have trailing newline)
            guard let accessURL = String(data: responseData, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                  !accessURL.isEmpty else {
                logger.error("Claim succeeded but response body is empty or invalid")
                throw SimpleFINError.invalidResponse
            }
            logger.info("Successfully claimed access URL")
            return accessURL
        case 403:
            logger.warning("Token already claimed or invalid (HTTP 403)")
            throw SimpleFINError.tokenAlreadyClaimed
        default:
            logger.error("Claim failed with HTTP \(httpResponse.statusCode)")
            if let responseBody = String(data: responseData, encoding: .utf8) {
                logger.error("Response body: \(responseBody)")
            }
            throw SimpleFINError.claimFailed(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Fetch Accounts

    /// Fetch accounts and transactions from SimpleFIN
    /// Access URL format: https://username:password@api.simplefin.org/simplefin
    ///
    /// - Parameters:
    ///   - startDate: Include transactions on/after this date (optional)
    ///   - endDate: Include transactions before this date (optional)
    ///   - includePending: Include pending transactions (default: false)
    ///   - accountIds: Filter to specific account IDs (optional, can specify multiple)
    ///   - balancesOnly: Return only balances, no transactions (default: false)
    func fetchAccounts(
        startDate: Date? = nil,
        endDate: Date? = nil,
        includePending: Bool = false,
        accountIds: [String]? = nil,
        balancesOnly: Bool = false
    ) async throws -> SimpleFINAccountSet {
        logger.info("Fetching accounts from SimpleFIN...")

        guard let accessURL = keychainService.getAccessURL() else {
            logger.error("No access URL found in keychain")
            throw SimpleFINError.noAccessToken
        }

        guard let (baseURL, username, password) = parseAccessURL(accessURL) else {
            logger.error("Failed to parse access URL - invalid format")
            throw SimpleFINError.invalidAccessURL
        }

        let url = try buildAccountsURL(
            baseURL: baseURL,
            startDate: startDate,
            endDate: endDate,
            includePending: includePending,
            accountIds: accountIds,
            balancesOnly: balancesOnly
        )

        logger.info("Request URL: \(url.absoluteString.replacingOccurrences(of: password, with: "***"))")

        let request = buildAuthenticatedRequest(url: url, username: username, password: password)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type received")
            throw SimpleFINError.invalidResponse
        }

        logger.info("Response status: \(httpResponse.statusCode)")
        logResponseHeaders(httpResponse)

        try validateFetchResponse(httpResponse, data: data)
        return try decodeAccountSet(from: data)
    }

    // MARK: - Fetch Accounts Helpers

    private func buildAccountsURL(
        baseURL: String,
        startDate: Date?,
        endDate: Date?,
        includePending: Bool,
        accountIds: [String]?,
        balancesOnly: Bool
    ) throws -> URL {
        var components = URLComponents(string: "\(baseURL)/accounts")
        var queryItems: [URLQueryItem] = []

        if let start = startDate {
            let timestamp = Int(start.timeIntervalSince1970)
            queryItems.append(URLQueryItem(name: "start-date", value: String(timestamp)))
            logger.debug("start-date: \(timestamp)")
        }
        if let end = endDate {
            let timestamp = Int(end.timeIntervalSince1970)
            queryItems.append(URLQueryItem(name: "end-date", value: String(timestamp)))
            logger.debug("end-date: \(timestamp)")
        }
        if includePending {
            queryItems.append(URLQueryItem(name: "pending", value: "1"))
            logger.debug("Including pending transactions")
        }
        if let ids = accountIds {
            for accountId in ids {
                queryItems.append(URLQueryItem(name: "account", value: accountId))
            }
            logger.debug("Filtering to \(ids.count) accounts")
        }
        if balancesOnly {
            queryItems.append(URLQueryItem(name: "balances-only", value: "1"))
            logger.debug("Requesting balances only")
        }

        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            logger.error("Failed to construct accounts URL")
            throw SimpleFINError.invalidAccessURL
        }
        return url
    }

    private func buildAuthenticatedRequest(url: URL, username: String, password: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let authString = "\(username):\(password)"
        if let authData = authString.data(using: .utf8) {
            let base64Auth = authData.base64EncodedString()
            request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func logResponseHeaders(_ httpResponse: HTTPURLResponse) {
        guard let headers = httpResponse.allHeaderFields as? [String: Any] else { return }
        for (key, value) in headers {
            logger.debug("Header: \(key) = \(String(describing: value))")
        }
    }

    private func validateFetchResponse(_ httpResponse: HTTPURLResponse, data: Data) throws {
        switch httpResponse.statusCode {
        case 200:
            return
        case 402:
            logger.error("Subscription required (HTTP 402) - payment needed")
            throw SimpleFINError.subscriptionRequired
        case 403:
            logger.error("Invalid credentials (HTTP 403) - access revoked or invalid")
            throw SimpleFINError.invalidCredentials
        case 500, 502, 503, 504:
            logger.error("Server error (HTTP \(httpResponse.statusCode))")
            logResponseBody(data, prefix: "Server error response")
            throw SimpleFINError.serverError
        default:
            logger.error("Unexpected status code: \(httpResponse.statusCode)")
            logResponseBody(data, prefix: "Response body")
            throw SimpleFINError.fetchFailed(statusCode: httpResponse.statusCode)
        }
    }

    private func logResponseBody(_ data: Data, prefix: String) {
        if let responseBody = String(data: data, encoding: .utf8) {
            logger.error("\(prefix): \(responseBody)")
        }
    }

    private func decodeAccountSet(from data: Data) throws -> SimpleFINAccountSet {
        logger.debug("Response size: \(data.count) bytes")
        do {
            let accountSet = try JSONDecoder().decode(SimpleFINAccountSet.self, from: data)
            logger.info("Successfully parsed \(accountSet.accounts.count) accounts")

            for error in accountSet.errors {
                logger.warning("SimpleFIN API error: \(error)")
            }
            return accountSet
        } catch {
            logger.error("Failed to decode response: \(error.localizedDescription)")
            if let responseBody = String(data: data, encoding: .utf8) {
                logger.debug("Raw response: \(responseBody.prefix(500))...")
            }
            throw error
        }
    }

    // MARK: - Helpers

    private func parseAccessURL(_ accessURL: String) -> (baseURL: String, username: String, password: String)? {
        // URL format: scheme://username:password@host[:port]/path
        guard let url = URL(string: accessURL),
              let host = url.host,
              let user = url.user,
              let pass = url.password else {
            return nil
        }

        let scheme = url.scheme ?? "https"
        let port = url.port.map { ":\($0)" } ?? ""
        let path = url.path
        let baseURL = "\(scheme)://\(host)\(port)\(path)"

        return (baseURL, user, pass)
    }
}

// MARK: - SimpleFIN Errors

enum SimpleFINError: LocalizedError {
    case invalidSetupToken
    case tokenAlreadyClaimed
    case claimFailed(statusCode: Int)
    case noAccessToken
    case invalidAccessURL
    case invalidResponse
    case fetchFailed(statusCode: Int)
    case rateLimited
    case subscriptionRequired
    case invalidCredentials
    case serverError

    var errorDescription: String? {
        switch self {
        case .invalidSetupToken:
            return "The setup token is invalid or malformed."
        case .tokenAlreadyClaimed:
            return "This setup token has already been claimed. Please generate a new one."
        case .claimFailed(let code):
            return "Failed to claim token (HTTP \(code))."
        case .noAccessToken:
            return "No SimpleFIN access token configured."
        case .invalidAccessURL:
            return "The access URL is invalid."
        case .invalidResponse:
            return "Received an invalid response from SimpleFIN."
        case .fetchFailed(let code):
            return "Failed to fetch accounts (HTTP \(code))."
        case .rateLimited:
            return "Rate limit exceeded. SimpleFIN allows 24 requests per day."
        case .subscriptionRequired:
            return "SimpleFIN subscription required. Please visit bridge.simplefin.org to activate or renew your subscription."
        case .invalidCredentials:
            return "SimpleFIN credentials are invalid. Please reconnect your account in Settings."
        case .serverError:
            return "SimpleFIN is temporarily unavailable. Please check your bank connections at bridge.simplefin.org and try again later."
        }
    }
}
