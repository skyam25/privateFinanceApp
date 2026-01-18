//
//  TransactionsView.swift
//  GhostVault
//
//  Transactions list - UI to be defined
//

import SwiftUI
import SwiftData

struct TransactionsView: View {
    var body: some View {
        NavigationStack {
            // TODO: Design transactions UI
            // - Unified transaction feed from all accounts
            // - Search and filter
            // - Category assignment
            // - Date grouping
            ContentUnavailableView {
                Label("Transactions", systemImage: "list.bullet.rectangle.fill")
            } description: {
                Text("Transactions UI to be designed")
            }
            .navigationTitle("Transactions")
        }
    }
}

#Preview {
    TransactionsView()
}
