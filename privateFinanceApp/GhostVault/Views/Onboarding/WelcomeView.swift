//
//  WelcomeView.swift
//  GhostVault
//
//  Welcome screen (Page 1 of onboarding)
//  Introduces the app and its privacy-first approach
//

import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App Icon
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 100))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            // App Name and Tagline
            VStack(spacing: 8) {
                Text("GhostVault")
                    .font(.largeTitle.bold())

                Text("Private Finance Tracking")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Privacy Value Proposition
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "iphone",
                    title: "Your Data Stays on Your Device",
                    description: "All financial data is stored locally. No cloud servers, no data mining."
                )

                FeatureRow(
                    icon: "lock.shield",
                    title: "Bank-Level Security",
                    description: "Protected by Face ID and the iOS Keychain."
                )

                FeatureRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Powered by SimpleFIN",
                    description: "Securely connects to your banks without sharing credentials."
                )
            }
            .padding(.horizontal)

            Spacer()

            // Get Started Button
            Button(action: onContinue) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)

            // SimpleFIN Requirement Note
            Text("Requires a SimpleFIN Bridge account ($1.50/month)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom)
        }
        .padding()
    }
}

// MARK: - Feature Row Component

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeView {
        print("Continue tapped")
    }
}
