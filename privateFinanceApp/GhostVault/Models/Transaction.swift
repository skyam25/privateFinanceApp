//
//  Transaction.swift
//  GhostVault
//
//  Data model for financial transactions from SimpleFIN
//

import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var id: String
    var accountId: String
    var posted: Date
    var amount: String // Store as string to preserve precision
    var transactionDescription: String
    var payee: String?
    var memo: String?
    var pending: Bool
    var category: String?
    var classificationReason: String? // "Default", "Payee Rule: [name]", "Auto-Transfer", etc.
    var isIgnored: Bool // Exclude from calculations

    // Computed properties

    /// Classification type for display badges
    var classificationType: ClassificationType {
        if isIgnored { return .ignored }
        guard let cat = category?.lowercased() else {
            return amountValue >= 0 ? .income : .expense
        }
        switch cat {
        case "income", "salary", "payroll":
            return .income
        case "transfer":
            return .transfer
        default:
            return amountValue >= 0 ? .income : .expense
        }
    }
    var amountValue: Decimal {
        Decimal(string: amount) ?? 0
    }

    var categoryIcon: String {
        guard let category = category else { return "questionmark.circle" }
        return TransactionCategory.icon(for: category)
    }

    // MARK: - Initialization

    init(
        id: String,
        accountId: String,
        posted: Date,
        amount: String,
        transactionDescription: String,
        payee: String? = nil,
        memo: String? = nil,
        pending: Bool = false,
        category: String? = nil,
        classificationReason: String? = "Default",
        isIgnored: Bool = false
    ) {
        self.id = id
        self.accountId = accountId
        self.posted = posted
        self.amount = amount
        self.transactionDescription = transactionDescription
        self.payee = payee
        self.memo = memo
        self.pending = pending
        self.category = category
        self.classificationReason = classificationReason
        self.isIgnored = isIgnored
    }

    // Initialize from SimpleFIN API response
    convenience init(from apiTransaction: SimpleFINTransaction, accountId: String) {
        self.init(
            id: apiTransaction.id,
            accountId: accountId,
            posted: Date(timeIntervalSince1970: TimeInterval(apiTransaction.posted)),
            amount: apiTransaction.amount,
            transactionDescription: apiTransaction.description,
            payee: apiTransaction.payee,
            memo: apiTransaction.memo,
            pending: apiTransaction.pending ?? false,
            category: nil // Will be categorized by local rules
        )
    }
}

// MARK: - Classification Type

import SwiftUI

enum ClassificationType: String, CaseIterable {
    case income
    case expense
    case transfer
    case ignored

    var displayName: String {
        switch self {
        case .income: return "Income"
        case .expense: return "Expense"
        case .transfer: return "Transfer"
        case .ignored: return "Ignored"
        }
    }

    var color: Color {
        switch self {
        case .income: return .green
        case .expense: return .red
        case .transfer: return .blue
        case .ignored: return .gray
        }
    }

    var iconName: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        case .ignored: return "minus.circle.fill"
        }
    }
}

// MARK: - Transaction Category Helper

enum TransactionCategory {
    static func icon(for category: String) -> String {
        switch category.lowercased() {
        case "food & dining", "food", "dining", "restaurants":
            return "fork.knife"
        case "shopping":
            return "bag"
        case "transportation", "auto", "gas":
            return "car"
        case "bills & utilities", "bills", "utilities":
            return "bolt"
        case "entertainment":
            return "tv"
        case "health & fitness", "health", "medical":
            return "heart"
        case "travel":
            return "airplane"
        case "income", "salary":
            return "arrow.down.circle"
        case "transfer":
            return "arrow.left.arrow.right"
        case "groceries":
            return "cart"
        case "subscriptions":
            return "repeat"
        default:
            return "questionmark.circle"
        }
    }
}
