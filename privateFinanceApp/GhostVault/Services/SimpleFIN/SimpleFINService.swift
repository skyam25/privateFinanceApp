//
//  SimpleFINService.swift
//  GhostVault
//
//  Service for interacting with SimpleFIN Bridge API
//  See: https://bridge.simplefin.org/info/developers
//

import Foundation

// MARK: - SimpleFIN API Service

actor SimpleFINService {
    private let keychainService = KeychainService()

    // MARK: - Token Exchange

    /// Exchange a setup token for an access URL
    /// The setup token is base64-encoded and contains the claim URL
    func claimSetupToken(_ setupToken: String) async throws -> String {
        // Step 1: Base64 decode the setup token to get the claim URL
        guard let data = Data(base64Encoded: setupToken),
              let claimURL = String(data: data, encoding: .utf8),
              let url = URL(string: claimURL) else {
            throw SimpleFINError.invalidSetupToken
        }

        // Step 2: POST to the claim URL to receive the access URL
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("0", forHTTPHeaderField: "Content-Length")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SimpleFINError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            guard let accessURL = String(data: data, encoding: .utf8) else {
                throw SimpleFINError.invalidResponse
            }
            return accessURL
        case 403:
            throw SimpleFINError.tokenAlreadyClaimed
        default:
            throw SimpleFINError.claimFailed(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Fetch Accounts

    /// Fetch accounts and transactions from SimpleFIN
    /// Access URL format: https://username:password@api.simplefin.org/simplefin
    func fetchAccounts(startDate: Date? = nil, endDate: Date? = nil) async throws -> SimpleFINAccountSet {
        guard let accessURL = keychainService.getAccessURL() else {
            throw SimpleFINError.noAccessToken
        }

        // Parse the access URL to extract auth credentials
        guard let (baseURL, username, password) = parseAccessURL(accessURL) else {
            throw SimpleFINError.invalidAccessURL
        }

        // Build the accounts URL with optional date parameters
        var components = URLComponents(string: "\(baseURL)/accounts")
        var queryItems: [URLQueryItem] = []

        if let start = startDate {
            queryItems.append(URLQueryItem(name: "start-date", value: String(Int(start.timeIntervalSince1970))))
        }
        if let end = endDate {
            queryItems.append(URLQueryItem(name: "end-date", value: String(Int(end.timeIntervalSince1970))))
        }

        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw SimpleFINError.invalidAccessURL
        }

        // Create request with Basic Auth
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let authString = "\(username):\(password)"
        if let authData = authString.data(using: .utf8) {
            let base64Auth = authData.base64EncodedString()
            request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SimpleFINError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw SimpleFINError.fetchFailed(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(SimpleFINAccountSet.self, from: data)
    }

    // MARK: - Helpers

    private func parseAccessURL(_ accessURL: String) -> (baseURL: String, username: String, password: String)? {
        // URL format: scheme://username:password@host/path
        guard let url = URL(string: accessURL),
              let host = url.host,
              let user = url.user,
              let pass = url.password else {
            return nil
        }

        let scheme = url.scheme ?? "https"
        let path = url.path
        let baseURL = "\(scheme)://\(host)\(path)"

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
        }
    }
}
