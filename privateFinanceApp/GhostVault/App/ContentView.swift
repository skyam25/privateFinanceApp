//
//  ContentView.swift
//  GhostVault
//
//  Main navigation container for the app
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .dashboard

    enum Tab {
        case dashboard
        case accounts
        case transactions
        case settings
    }

    var body: some View {
        Group {
            if !appState.isOnboarded {
                OnboardingView()
            } else {
                mainTabView
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
                .tag(Tab.dashboard)

            AccountsView()
                .tabItem {
                    Label("Accounts", systemImage: "building.columns.fill")
                }
                .tag(Tab.accounts)

            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle.fill")
                }
                .tag(Tab.transactions)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
