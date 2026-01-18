//
//  RuleEngine.swift
//  GhostVault
//
//  Classification rule engine with priority-based resolution
//

import Foundation

/// Engine for applying classification rules to transactions
struct RuleEngine {

    // MARK: - Rule Application

    /// Apply the best matching rule to a transaction
    /// - Parameters:
    ///   - transaction: The transaction to classify
    ///   - rules: Available user-defined rules
    ///   - force: If true, override existing classification regardless of priority
    /// - Returns: True if a rule was applied
    @discardableResult
    static func applyBestRule(
        to transaction: Transaction,
        rules: [ClassificationRule],
        force: Bool = false
    ) -> Bool {
        // Find matching rules
        let matchingRules = rules.filter { $0.matches(transaction) }
        guard let bestRule = matchingRules.first else { return false }

        // Check if we should override existing classification
        let existingPriority = ClassificationPriority.from(reason: transaction.classificationReason)
        let rulePriority = ClassificationPriority.payeeRule

        if force || rulePriority > existingPriority {
            bestRule.apply(to: transaction)
            return true
        }

        return false
    }

    /// Apply classification to a transaction using the full priority chain
    /// Priority: user payee rules > manual override > auto-transfer > auto-CC payment > pattern income > default
    /// - Parameters:
    ///   - transaction: The transaction to classify
    ///   - rules: User-defined rules
    ///   - allTransactions: All transactions (for transfer detection)
    /// - Returns: The classification priority level that was applied
    @discardableResult
    static func classify(
        transaction: Transaction,
        rules: [ClassificationRule],
        allTransactions: [Transaction] = []
    ) -> ClassificationPriority {
        // 1. Check for user payee rules (highest priority)
        if applyBestRule(to: transaction, rules: rules) {
            return .payeeRule
        }

        // 2. Manual classification is already set - don't override
        if transaction.classificationReason == "Manual" {
            return .manual
        }

        // 3. Check for auto-transfer (already matched)
        if transaction.isMatchedTransfer {
            return .autoTransfer
        }

        // 4. Check for auto-CC payment patterns
        if applyCCPaymentDetection(to: transaction) {
            return .autoCCPayment
        }

        // 5. Check for income patterns
        if IncomeDetector.processTransaction(transaction) {
            return .patternIncome
        }

        // 6. Default classification
        if transaction.category == nil {
            applyDefaultClassification(to: transaction)
        }

        return .default
    }

    /// Classify multiple transactions
    /// - Parameters:
    ///   - transactions: Transactions to classify
    ///   - rules: User-defined rules
    static func classifyAll(
        transactions: [Transaction],
        rules: [ClassificationRule]
    ) {
        // First detect transfers (needs all transactions)
        TransferDetector.processTransfers(transactions)

        // Then classify each transaction
        for transaction in transactions {
            classify(transaction: transaction, rules: rules)
        }
    }

    // MARK: - CC Payment Detection

    /// Detect and classify credit card payments
    private static let ccPaymentPatterns = [
        "credit card payment",
        "cc payment",
        "card payment",
        "payment to card",
        "autopay payment",
        "minimum payment",
        "statement balance"
    ]

    /// Check if transaction is a CC payment and apply classification
    static func applyCCPaymentDetection(to transaction: Transaction) -> Bool {
        guard transaction.amountValue < 0 else { return false }
        guard !transaction.isMatchedTransfer else { return false }

        let description = transaction.transactionDescription.lowercased()
        let payee = transaction.payee?.lowercased() ?? ""

        for pattern in ccPaymentPatterns {
            if description.contains(pattern) || payee.contains(pattern) {
                transaction.category = "Transfer"
                transaction.classificationReason = "Auto-CC Payment"
                return true
            }
        }

        return false
    }

    // MARK: - Default Classification

    /// Apply default classification based on amount
    static func applyDefaultClassification(to transaction: Transaction) {
        if transaction.amountValue >= 0 {
            transaction.category = "Income"
        } else {
            transaction.category = "Expense"
        }
        transaction.classificationReason = "Default"
    }

    // MARK: - Rule Creation

    /// Create a rule from a transaction (for "Apply to all" action)
    /// - Parameters:
    ///   - transaction: The transaction to base the rule on
    ///   - category: The category to apply
    ///   - classificationType: The classification type
    /// - Returns: A new ClassificationRule, or nil if no payee
    static func createRule(
        from transaction: Transaction,
        category: String,
        classificationType: String = "expense"
    ) -> ClassificationRule? {
        guard let payee = transaction.payee, !payee.isEmpty else {
            // Fall back to first significant word of description
            let words = transaction.transactionDescription.split(separator: " ")
            guard let firstWord = words.first, firstWord.count >= 3 else {
                return nil
            }
            return ClassificationRule(
                payee: String(firstWord),
                category: category,
                classificationType: classificationType
            )
        }

        return ClassificationRule(
            payee: payee,
            category: category,
            classificationType: classificationType
        )
    }

    // MARK: - Priority Checking

    /// Check if a new classification can override existing classification
    /// - Parameters:
    ///   - newReason: The reason for the new classification
    ///   - existingReason: The existing classification reason
    /// - Returns: True if the new classification has higher priority
    static func canOverride(newReason: String, existingReason: String?) -> Bool {
        let newPriority = ClassificationPriority.from(reason: newReason)
        let existingPriority = ClassificationPriority.from(reason: existingReason)
        return newPriority > existingPriority
    }

    /// Get the priority of a transaction's current classification
    static func priority(of transaction: Transaction) -> ClassificationPriority {
        ClassificationPriority.from(reason: transaction.classificationReason)
    }

    // MARK: - Statistics

    /// Count transactions by classification reason
    static func countByReason(_ transactions: [Transaction]) -> [String: Int] {
        var counts: [String: Int] = [:]
        for transaction in transactions {
            let reason = transaction.classificationReason ?? "Default"
            counts[reason, default: 0] += 1
        }
        return counts
    }

    /// Count transactions that would match a rule
    static func countMatches(for rule: ClassificationRule, in transactions: [Transaction]) -> Int {
        transactions.filter { rule.matches($0) }.count
    }
}
