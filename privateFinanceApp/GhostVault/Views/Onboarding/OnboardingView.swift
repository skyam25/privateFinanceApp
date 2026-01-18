//
//  OnboardingView.swift
//  GhostVault
//
//  Multi-page onboarding flow
//  Page 1: Welcome - privacy pitch
//  Page 2: Token entry or SimpleFIN signup
//  Page 3: Account discovery
//  Page 4: Classification review
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage: OnboardingPage = .welcome

    private let simpleFINService = SimpleFINService()
    private let keychainService = KeychainService()

    var body: some View {
        NavigationStack {
            Group {
                switch currentPage {
                case .welcome:
                    WelcomeView {
                        withAnimation {
                            currentPage = .tokenEntry
                        }
                    }

                case .tokenEntry:
                    TokenEntryView(
                        onTokenClaimed: { _ in
                            withAnimation {
                                currentPage = .accountDiscovery
                            }
                        },
                        onBack: {
                            withAnimation {
                                currentPage = .welcome
                            }
                        },
                        onSignUp: {
                            withAnimation {
                                currentPage = .webView
                            }
                        }
                    )

                case .webView:
                    SimpleFINWebView(
                        onTokenDetected: { token in
                            // Auto-validate and proceed
                            Task {
                                await claimAndProceed(token: token)
                            }
                        },
                        onManualPaste: {
                            // Fall back to token entry
                            withAnimation {
                                currentPage = .tokenEntry
                            }
                        },
                        onCancel: {
                            withAnimation {
                                currentPage = .tokenEntry
                            }
                        }
                    )

                case .accountDiscovery:
                    AccountDiscoveryView(
                        onContinue: {
                            withAnimation {
                                currentPage = .classificationReview
                            }
                        },
                        onBack: {
                            withAnimation {
                                currentPage = .tokenEntry
                            }
                        }
                    )

                case .classificationReview:
                    // Placeholder until P1-T5
                    ClassificationReviewPlaceholderView {
                        appState.isOnboarded = true
                    } onBack: {
                        withAnimation {
                            currentPage = .accountDiscovery
                        }
                    }
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
        }
    }

    // MARK: - Token Claiming

    private func claimAndProceed(token: String) async {
        do {
            let accessURL = try await simpleFINService.claimSetupToken(token)
            keychainService.saveAccessURL(accessURL)
            await MainActor.run {
                withAnimation {
                    currentPage = .accountDiscovery
                }
            }
        } catch {
            // On error, fall back to manual token entry
            await MainActor.run {
                withAnimation {
                    currentPage = .tokenEntry
                }
            }
        }
    }
}

// MARK: - Onboarding Pages

enum OnboardingPage {
    case welcome
    case tokenEntry
    case webView
    case accountDiscovery
    case classificationReview
}

// MARK: - Placeholder Views (to be replaced in subsequent tasks)

private struct ClassificationReviewPlaceholderView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "tag.fill")
                .font(.system(size: 60))
                .foregroundStyle(.accent)
            Text("Review Transactions")
                .font(.title2.bold())
            Text("Classification review screen coming in P1-T5")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Continue to Dashboard", action: onContinue)
                .buttonStyle(.borderedProminent)
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
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
