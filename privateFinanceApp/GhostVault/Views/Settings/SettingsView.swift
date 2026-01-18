//
//  SettingsView.swift
//  GhostVault
//
//  Settings and SimpleFIN connection - UI to be defined
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            // TODO: Design settings UI
            // - SimpleFIN connection status and token entry
            // - Data management
            // - Category rules
            // - Security (biometrics)
            // - Export options
            ContentUnavailableView {
                Label("Settings", systemImage: "gear")
            } description: {
                Text("Settings UI to be designed")
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
