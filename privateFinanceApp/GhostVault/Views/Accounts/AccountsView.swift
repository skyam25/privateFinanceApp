//
//  AccountsView.swift
//  GhostVault
//
//  Accounts list - UI to be defined
//

import SwiftUI
import SwiftData

struct AccountsView: View {
    var body: some View {
        NavigationStack {
            // TODO: Design accounts UI
            // - List of connected accounts grouped by institution
            // - Account balance and type
            // - Tap to view account transactions
            ContentUnavailableView {
                Label("Accounts", systemImage: "building.columns.fill")
            } description: {
                Text("Accounts UI to be designed")
            }
            .navigationTitle("Accounts")
        }
    }
}

#Preview {
    AccountsView()
}
