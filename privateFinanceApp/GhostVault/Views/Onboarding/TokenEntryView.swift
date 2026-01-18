//
//  TokenEntryView.swift
//  GhostVault
//
//  SimpleFIN token entry screen (Page 2 of onboarding)
//  Allows users to paste a setup token or sign up for SimpleFIN
//

import SwiftUI

struct TokenEntryView: View {
    let onTokenClaimed: (String) -> Void
    let onBack: () -> Void
    let onSignUp: () -> Void

    @State private var tokenText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var selectedPath: TokenEntryPath = .haveToken

    private let simpleFINService = SimpleFINService()
    private let keychainService = KeychainService()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Header
            VStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.accent)

                Text("Connect to SimpleFIN")
                    .font(.title2.bold())

                Text("SimpleFIN securely syncs your bank accounts without storing your credentials.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Path Selection
            Picker("", selection: $selectedPath) {
                Text("I have a token").tag(TokenEntryPath.haveToken)
                Text("I need an account").tag(TokenEntryPath.needAccount)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Content based on selected path
            if selectedPath == .haveToken {
                tokenEntryContent
            } else {
                signUpContent
            }

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                }
            }
        }
    }

    // MARK: - Token Entry Content

    private var tokenEntryContent: some View {
        VStack(spacing: 16) {
            // Token text field with paste button
            HStack {
                TextField("Paste your setup token here", text: $tokenText)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .disabled(isLoading)

                Button {
                    if let pastedText = UIPasteboard.general.string {
                        tokenText = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .font(.title3)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal)

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Connect button
            Button {
                Task {
                    await claimToken()
                }
            } label: {
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Connecting...")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                } else {
                    Text("Connect")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(tokenText.isEmpty || isLoading)
            .padding(.horizontal)
        }
    }

    // MARK: - Sign Up Content

    private var signUpContent: some View {
        VStack(spacing: 16) {
            Text("SimpleFIN Bridge costs $1.50/month and connects to 12,000+ financial institutions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                onSignUp()
            } label: {
                Text("Sign Up for SimpleFIN")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
        }
    }

    // MARK: - Token Claiming

    private func claimToken() async {
        errorMessage = nil
        isLoading = true

        defer {
            isLoading = false
        }

        // Validate token format first
        let validation = TokenValidator.validate(tokenText)
        guard validation.isValid else {
            errorMessage = validation.errorMessage
            return
        }

        do {
            let accessURL = try await simpleFINService.claimSetupToken(tokenText)
            keychainService.saveAccessURL(accessURL)
            await MainActor.run {
                onTokenClaimed(accessURL)
            }
        } catch let error as SimpleFINError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }
    }
}

// MARK: - Token Entry Path

enum TokenEntryPath {
    case haveToken
    case needAccount
}

// MARK: - Token Validator

struct TokenValidator {
    struct ValidationResult {
        let isValid: Bool
        let errorMessage: String?
    }

    /// Validates the format of a SimpleFIN setup token
    /// Setup tokens are base64-encoded URLs
    static func validate(_ token: String) -> ValidationResult {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if empty
        guard !trimmedToken.isEmpty else {
            return ValidationResult(isValid: false, errorMessage: "Please enter a setup token.")
        }

        // Check minimum length (base64-encoded URL should be reasonably long)
        guard trimmedToken.count >= 20 else {
            return ValidationResult(isValid: false, errorMessage: "Token appears too short. Please check and try again.")
        }

        // Check if it's valid base64
        guard let decodedData = Data(base64Encoded: trimmedToken) else {
            return ValidationResult(isValid: false, errorMessage: "Invalid token format. Make sure you copied the entire token.")
        }

        // Check if decoded data is a valid URL string with http/https scheme
        guard let decodedString = String(data: decodedData, encoding: .utf8),
              let url = URL(string: decodedString),
              let scheme = url.scheme?.lowercased(),
              (scheme == "http" || scheme == "https") else {
            return ValidationResult(isValid: false, errorMessage: "Token does not contain a valid URL. Please get a new token from SimpleFIN.")
        }

        return ValidationResult(isValid: true, errorMessage: nil)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TokenEntryView(
            onTokenClaimed: { _ in print("Token claimed") },
            onBack: { print("Back tapped") },
            onSignUp: { print("Sign up tapped") }
        )
    }
}
