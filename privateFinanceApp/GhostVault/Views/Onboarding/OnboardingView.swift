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
                            // Will navigate to WebView in P1-T3
                            print("Sign up for SimpleFIN")
                        }
                    )

                case .accountDiscovery:
                    // Placeholder until P1-T4
                    AccountDiscoveryPlaceholderView {
                        withAnimation {
                            currentPage = .classificationReview
                        }
                    } onBack: {
                        withAnimation {
                            currentPage = .tokenEntry
                        }
                    }

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
}

// MARK: - Onboarding Pages

enum OnboardingPage {
    case welcome
    case tokenEntry
    case accountDiscovery
    case classificationReview
}

// MARK: - Placeholder Views (to be replaced in subsequent tasks)

private struct AccountDiscoveryPlaceholderView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "building.columns.fill")
                .font(.system(size: 60))
                .foregroundStyle(.accent)
            Text("Your Accounts")
                .font(.title2.bold())
            Text("Account discovery screen coming in P1-T4")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Continue", action: onContinue)
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
