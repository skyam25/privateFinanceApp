//
//  OnboardingView.swift
//  GhostVault
//
//  Onboarding flow - UI to be defined
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        // TODO: Design onboarding flow
        // Page 1: Welcome - privacy pitch
        // Page 2: How it works - SimpleFIN explanation
        // Page 3: Connect - token entry or SimpleFIN signup
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 80))
                .foregroundStyle(.accent)

            Text("GhostVault")
                .font(.largeTitle.bold())

            Text("Your finances. Your device. Your privacy.")
                .foregroundStyle(.secondary)

            Spacer()

            Button("Get Started") {
                appState.isOnboarded = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
