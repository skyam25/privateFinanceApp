//
//  AccountTransactionsListView.swift
//  GhostVault
//
//  Full transaction list view for a specific account
//

import SwiftUI
import SwiftData

struct AccountTransactionsListView: View {
    let accountId: String
    let accountName: String

    @Query private var transactions: [Transaction]

    init(accountId: String, accountName: String) {
        self.accountId = accountId
        self.accountName = accountName
        _transactions = Query(
            filter: #Predicate<Transaction> { transaction in
                transaction.accountId == accountId
            },
            sort: \Transaction.posted,
            order: .reverse
        )
    }

    var body: some View {
        List {
            ForEach(transactions) { transaction in
                TransactionRowView(transaction: transaction)
            }
        }
        .listStyle(.plain)
        .navigationTitle(accountName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
