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
    var matchedTransferId: String? // ID of the matched transfer transaction

    // Computed properties

    /// Whether this transaction has been matched with a transfer
    var isMatchedTransfer: Bool {
        matchedTransferId != nil
    }

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
        isIgnored: Bool = false,
        matchedTransferId: String? = nil
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
        self.matchedTransferId = matchedTransferId
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
    private static let iconMap: [String: String] = [
        "food & dining": "fork.knife", "food": "fork.knife", "dining": "fork.knife", "restaurants": "fork.knife",
        "shopping": "bag",
        "transportation": "car", "auto": "car", "gas": "car",
        "bills & utilities": "bolt", "bills": "bolt", "utilities": "bolt",
        "entertainment": "tv",
        "health & fitness": "heart", "health": "heart", "medical": "heart",
        "travel": "airplane",
        "income": "arrow.down.circle", "salary": "arrow.down.circle",
        "transfer": "arrow.left.arrow.right",
        "groceries": "cart",
        "subscriptions": "repeat"
    ]

    static func icon(for category: String) -> String {
        iconMap[category.lowercased()] ?? "questionmark.circle"
    }
}
