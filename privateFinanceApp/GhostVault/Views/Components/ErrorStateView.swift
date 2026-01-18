//
//  ErrorStateView.swift
//  GhostVault
//
//  Error state components and error handling UI
//

import SwiftUI

// MARK: - Sync Error Type

enum SyncErrorType: Equatable {
    case networkUnreachable
    case tokenExpired
    case rateLimited(resetTime: TimeInterval)
    case partialFailure(failedAccounts: [String])
    case serverError(message: String)
    case unknown(message: String)

    var title: String {
        switch self {
        case .networkUnreachable:
            return "Connection Error"
        case .tokenExpired:
            return "Session Expired"
        case .rateLimited:
            return "Rate Limited"
        case .partialFailure:
            return "Partial Sync Failure"
        case .serverError:
            return "Server Error"
        case .unknown:
            return "Sync Error"
        }
    }

    var icon: String {
        switch self {
        case .networkUnreachable:
            return "wifi.slash"
        case .tokenExpired:
            return "key.slash"
        case .rateLimited:
            return "hourglass"
        case .partialFailure:
            return "exclamationmark.triangle"
        case .serverError:
            return "server.rack"
        case .unknown:
            return "xmark.circle"
        }
    }

    var iconColor: Color {
        switch self {
        case .networkUnreachable:
            return .orange
        case .tokenExpired:
            return .red
        case .rateLimited:
            return .yellow
        case .partialFailure:
            return .orange
        case .serverError, .unknown:
            return .red
        }
    }

    var description: String {
        switch self {
        case .networkUnreachable:
            return "Unable to reach SimpleFIN. Check your internet connection and try again."
        case .tokenExpired:
            return "Your SimpleFIN session has expired. Please reconnect to continue syncing."
        case .rateLimited(let resetTime):
            let minutes = Int(resetTime / 60)
            return "Daily sync limit reached. Syncing will be available again in \(minutes) minutes."
        case .partialFailure(let accounts):
            if accounts.count == 1 {
                return "Failed to sync \(accounts[0]). Other accounts synced successfully."
            } else {
                return "Failed to sync \(accounts.count) accounts. Other accounts synced successfully."
            }
        case .serverError(let message):
            return "SimpleFIN server error: \(message)"
        case .unknown(let message):
            return message
        }
    }

    var actionLabel: String? {
        switch self {
        case .networkUnreachable:
            return "Retry"
        case .tokenExpired:
            return "Reconnect"
        case .rateLimited:
            return nil
        case .partialFailure:
            return "Retry Failed"
        case .serverError, .unknown:
            return "Retry"
        }
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let error: SyncErrorType
    var onAction: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: error.icon)
                .font(.system(size: 48))
                .foregroundStyle(error.iconColor)

            // Title
            Text(error.title)
                .font(.title2)
                .fontWeight(.bold)

            // Description
            Text(error.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Failed accounts list for partial failure
            if case .partialFailure(let accounts) = error, accounts.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(accounts, id: \.self) { account in
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                            Text(account)
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Action button
            HStack(spacing: 12) {
                if let actionLabel = error.actionLabel, let onAction = onAction {
                    Button(actionLabel, action: onAction)
                        .buttonStyle(.borderedProminent)
                }

                if let onDismiss = onDismiss {
                    Button("Dismiss", action: onDismiss)
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding()
    }
}

// MARK: - Error Banner View

struct ErrorBannerView: View {
    let error: SyncErrorType
    var onAction: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.icon)
                .foregroundStyle(error.iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(error.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(error.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if let actionLabel = error.actionLabel, let onAction = onAction {
                Button(actionLabel, action: onAction)
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }

            if let onDismiss = onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Error Alert Modifier

struct SyncErrorAlert: ViewModifier {
    @Binding var error: SyncErrorType?
    var onRetry: () -> Void
    var onReconnect: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(
                error?.title ?? "Error",
                isPresented: .init(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                switch error {
                case .tokenExpired:
                    Button("Reconnect", action: onReconnect)
                    Button("Cancel", role: .cancel) { error = nil }

                case .rateLimited:
                    Button("OK", role: .cancel) { error = nil }

                default:
                    Button("Retry", action: onRetry)
                    Button("Cancel", role: .cancel) { error = nil }
                }
            } message: {
                if let error = error {
                    Text(error.description)
                }
            }
    }
}

extension View {
    func syncErrorAlert(
        error: Binding<SyncErrorType?>,
        onRetry: @escaping () -> Void,
        onReconnect: @escaping () -> Void
    ) -> some View {
        modifier(SyncErrorAlert(error: error, onRetry: onRetry, onReconnect: onReconnect))
    }
}

// MARK: - Error State Manager

@MainActor
class SyncErrorManager: ObservableObject {
    @Published var currentError: SyncErrorType?
    @Published var showingError = false

    func handleError(_ error: Error) {
        if let syncError = mapToSyncError(error) {
            currentError = syncError
            showingError = true
        }
    }

    func clearError() {
        currentError = nil
        showingError = false
    }

    private func mapToSyncError(_ error: Error) -> SyncErrorType? {
        if let networkError = mapNetworkError(error) {
            return networkError
        }
        if let simpleFINError = error as? SimpleFINError {
            return mapSimpleFINError(simpleFINError)
        }
        return .unknown(message: error.localizedDescription)
    }

    private func mapNetworkError(_ error: Error) -> SyncErrorType? {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else { return nil }

        switch nsError.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return .networkUnreachable
        case NSURLErrorTimedOut:
            return .serverError(message: "Connection timed out")
        default:
            return .networkUnreachable
        }
    }

    private func mapSimpleFINError(_ error: SimpleFINError) -> SyncErrorType {
        switch error {
        case .invalidSetupToken, .tokenAlreadyClaimed, .claimFailed,
             .noAccessToken, .invalidAccessURL, .invalidCredentials:
            return .tokenExpired
        case .invalidResponse:
            return .serverError(message: "Invalid response from server")
        case .fetchFailed(let statusCode):
            return mapFetchFailedError(statusCode: statusCode)
        case .rateLimited:
            return .rateLimited(resetTime: 3600)
        case .subscriptionRequired:
            return .serverError(message: "SimpleFIN subscription required. Please visit bridge.simplefin.org to activate.")
        case .serverError:
            return .serverError(message: "SimpleFIN is temporarily unavailable. Please try again later.")
        }
    }

    private func mapFetchFailedError(statusCode: Int) -> SyncErrorType {
        switch statusCode {
        case 401, 403:
            return .tokenExpired
        case 429:
            return .rateLimited(resetTime: 3600)
        default:
            return .serverError(message: "Server returned error \(statusCode)")
        }
    }
}

// MARK: - Previews

#Preview("Network Error") {
    ErrorStateView(error: .networkUnreachable) {
        print("Retry")
    } onDismiss: {
        print("Dismiss")
    }
}

#Preview("Token Expired") {
    ErrorStateView(error: .tokenExpired) {
        print("Reconnect")
    }
}

#Preview("Rate Limited") {
    ErrorStateView(error: .rateLimited(resetTime: 3600))
}

#Preview("Partial Failure") {
    ErrorStateView(
        error: .partialFailure(failedAccounts: ["Chase Checking", "Amex Card"])
    ) {
        print("Retry")
    }
}

#Preview("Error Banner") {
    VStack(spacing: 16) {
        ErrorBannerView(error: .networkUnreachable) {
            print("Retry")
        } onDismiss: {
            print("Dismiss")
        }

        ErrorBannerView(error: .tokenExpired) {
            print("Reconnect")
        }

        ErrorBannerView(error: .rateLimited(resetTime: 1800))
    }
    .padding()
}
