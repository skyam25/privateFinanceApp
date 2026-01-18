//
//  DashboardView.swift
//  GhostVault
//
//  Main dashboard - UI to be defined
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            // TODO: Design dashboard UI
            // - Net Worth card
            // - Safe to Spend daily number
            // - Account overview
            // - Recent transactions
            ContentUnavailableView {
                Label("Dashboard", systemImage: "chart.pie.fill")
            } description: {
                Text("Dashboard UI to be designed")
            }
            .navigationTitle("Dashboard")
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
}
