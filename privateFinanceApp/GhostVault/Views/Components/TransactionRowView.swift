//
//  TransactionRowView.swift
//  GhostVault
//
//  Simple transaction row view with category icon for account detail views
//

import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: transaction.categoryIcon)
                    .font(.subheadline)
                    .foregroundStyle(categoryColor)
            }

            // Description and date
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.payee ?? transaction.transactionDescription)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(transaction.posted, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedAmount)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(amountColor)

                if transaction.pending {
                    Text("Pending")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var formattedAmount: String {
        CurrencyFormatter.format(transaction.amountValue, maximumFractionDigits: 2)
    }

    private var amountColor: Color {
        transaction.amountValue >= 0 ? .green : .primary
    }

    private var categoryColor: Color {
        switch transaction.category?.lowercased() {
        case "income", "salary":
            return .green
        case "transfer":
            return .blue
        case "food", "dining", "restaurants", "food & dining":
            return .orange
        case "shopping":
            return .purple
        case "groceries":
            return .teal
        default:
            return .gray
        }
    }
}
