//
//  ClassificationRule.swift
//  GhostVault
//
//  SwiftData model for user-defined classification rules
//

import Foundation
import SwiftData

/// A user-defined rule for classifying transactions
@Model
final class ClassificationRule {
    @Attribute(.unique) var id: String
    var payee: String // The payee pattern to match
    var category: String // The category to apply
    var classificationType: String // "income", "expense", "transfer", "ignored"
    var createdAt: Date
    var isActive: Bool

    init(
        id: String = UUID().uuidString,
        payee: String,
        category: String,
        classificationType: String = "expense",
        createdAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.payee = payee
        self.category = category
        self.classificationType = classificationType
        self.createdAt = createdAt
        self.isActive = isActive
    }

    /// Check if this rule matches a transaction
    func matches(_ transaction: Transaction) -> Bool {
        guard isActive else { return false }

        let transactionPayee = transaction.payee?.lowercased() ?? ""
        let transactionDesc = transaction.transactionDescription.lowercased()
        let rulePayee = payee.lowercased()

        // Match if payee contains the rule pattern
        return transactionPayee.contains(rulePayee) || transactionDesc.contains(rulePayee)
    }

    /// Apply this rule to a transaction
    func apply(to transaction: Transaction) {
        transaction.category = category
        transaction.classificationReason = "Payee Rule: \(payee)"
    }
}

// MARK: - Classification Priority

/// Priority levels for classification resolution
enum ClassificationPriority: Int, Comparable {
    case `default` = 0
    case patternIncome = 1
    case autoTransfer = 2
    case autoCCPayment = 3
    case manual = 4
    case payeeRule = 5

    static func < (lhs: ClassificationPriority, rhs: ClassificationPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Get the priority for a given classification reason
    static func from(reason: String?) -> ClassificationPriority {
        guard let reason = reason?.lowercased() else { return .default }

        if reason.starts(with: "payee rule") {
            return .payeeRule
        } else if reason == "manual" {
            return .manual
        } else if reason.contains("auto-cc") || reason.contains("cc payment") {
            return .autoCCPayment
        } else if reason.contains("auto-transfer") {
            return .autoTransfer
        } else if reason.starts(with: "pattern") {
            return .patternIncome
        } else {
            return .default
        }
    }
}
