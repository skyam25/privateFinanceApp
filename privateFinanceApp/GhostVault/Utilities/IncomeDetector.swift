//
//  IncomeDetector.swift
//  GhostVault
//
//  Utility for detecting income transactions using pattern matching
//

import Foundation

/// Detects income transactions using regex pattern matching
struct IncomeDetector {

    // MARK: - Income Patterns

    /// Regex patterns that indicate an income transaction
    static let incomePatterns: [(pattern: String, reason: String)] = [
        // Payroll patterns
        ("payroll", "Payroll"),
        ("direct\\s*dep(osit)?", "Direct Deposit"),
        ("salary", "Salary"),
        ("wages?", "Wages"),
        ("pay\\s*check", "Paycheck"),
        ("ach\\s*credit.*payroll", "ACH Payroll"),

        // Employer patterns
        ("employer\\s*(payment|deposit)", "Employer Payment"),
        ("compensation", "Compensation"),

        // Deposit patterns
        ("ach\\s*credit", "ACH Credit"),
        ("wire\\s*transfer\\s*(in|credit|deposit)", "Wire Transfer"),
        ("direct\\s*deposit", "Direct Deposit"),

        // Government/Benefits patterns
        ("ssa\\s*(treas|payment)", "Social Security"),
        ("social\\s*security", "Social Security"),
        ("ssi\\s*(payment|deposit)", "SSI Payment"),
        ("irs\\s*(treas|refund)", "IRS Refund"),
        ("tax\\s*refund", "Tax Refund"),
        ("unemployment", "Unemployment"),
        ("disability\\s*(payment|benefit)", "Disability"),

        // Investment income
        ("dividend", "Dividend"),
        ("interest\\s*(payment|credit)", "Interest"),

        // Other income
        ("refund", "Refund"),
        ("rebate", "Rebate"),
        ("reimbursement", "Reimbursement"),
        ("cashback", "Cashback"),
        ("bonus", "Bonus")
    ]

    // MARK: - Detection

    /// Check if a transaction matches any income pattern
    /// - Parameter transaction: The transaction to check
    /// - Returns: Tuple of (isIncome, patternName) if matched, nil otherwise
    static func detectIncome(_ transaction: Transaction) -> (isIncome: Bool, reason: String)? {
        // Only check positive amounts (credits)
        guard transaction.amountValue > 0 else { return nil }

        // Skip if already classified as transfer or ignored
        guard !transaction.isIgnored else { return nil }
        guard transaction.category?.lowercased() != "transfer" else { return nil }

        // Check description and payee
        let textToCheck = [
            transaction.transactionDescription,
            transaction.payee ?? "",
            transaction.memo ?? ""
        ].joined(separator: " ")

        if let reason = matchesIncomePattern(textToCheck) {
            return (true, reason)
        }

        return nil
    }

    /// Check if text matches any income pattern
    /// - Parameter text: Text to check against patterns
    /// - Returns: The matched pattern reason, or nil if no match
    static func matchesIncomePattern(_ text: String) -> String? {
        let lowercased = text.lowercased()

        for (pattern, reason) in incomePatterns {
            do {
                let regex = try NSRegularExpression(
                    pattern: pattern,
                    options: [.caseInsensitive]
                )
                let range = NSRange(lowercased.startIndex..., in: lowercased)
                if regex.firstMatch(in: lowercased, options: [], range: range) != nil {
                    return reason
                }
            } catch {
                // Skip invalid patterns
                continue
            }
        }

        return nil
    }

    // MARK: - Apply Classification

    /// Apply income classification to a transaction
    /// - Parameters:
    ///   - transaction: The transaction to classify
    ///   - reason: The matched pattern reason
    static func applyIncomeClassification(to transaction: Transaction, reason: String) {
        transaction.category = "Income"
        transaction.classificationReason = "Pattern: \(reason)"
    }

    /// Process a transaction and classify if it matches income patterns
    /// - Parameter transaction: The transaction to process
    /// - Returns: True if the transaction was classified as income
    @discardableResult
    static func processTransaction(_ transaction: Transaction) -> Bool {
        guard let (isIncome, reason) = detectIncome(transaction), isIncome else {
            return false
        }

        applyIncomeClassification(to: transaction, reason: reason)
        return true
    }

    /// Process multiple transactions and classify any that match income patterns
    /// - Parameter transactions: The transactions to process
    /// - Returns: Count of transactions classified as income
    @discardableResult
    static func processTransactions(_ transactions: [Transaction]) -> Int {
        var count = 0
        for transaction in transactions {
            if processTransaction(transaction) {
                count += 1
            }
        }
        return count
    }

    // MARK: - Pattern Testing

    /// Test if a specific pattern matches text
    /// - Parameters:
    ///   - pattern: The regex pattern
    ///   - text: Text to test
    /// - Returns: True if the pattern matches
    static func patternMatches(_ pattern: String, in text: String) -> Bool {
        do {
            let regex = try NSRegularExpression(
                pattern: pattern,
                options: [.caseInsensitive]
            )
            let range = NSRange(text.startIndex..., in: text)
            return regex.firstMatch(in: text, options: [], range: range) != nil
        } catch {
            return false
        }
    }

    // MARK: - Statistics

    /// Count unclassified positive transactions
    /// - Parameter transactions: All transactions
    /// - Returns: Count of positive transactions without income classification
    static func countPotentialIncome(in transactions: [Transaction]) -> Int {
        transactions.filter { transaction in
            transaction.amountValue > 0 &&
            !transaction.isIgnored &&
            transaction.category?.lowercased() != "income" &&
            transaction.category?.lowercased() != "transfer"
        }.count
    }

    /// Get all pattern names
    static var allPatternNames: [String] {
        incomePatterns.map { $0.reason }
    }
}
