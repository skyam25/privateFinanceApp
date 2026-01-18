//
//  InlineErrorView.swift
//  GhostVault
//
//  Inline error display with retry action for onboarding and loading states
//

import SwiftUI

struct InlineErrorView: View {
    let errorMessage: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text(errorMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(buttonTitle) {
                action()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
