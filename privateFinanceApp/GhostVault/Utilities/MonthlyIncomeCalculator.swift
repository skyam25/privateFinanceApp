//
//  MonthlyIncomeCalculator.swift
//  GhostVault
//
//  Calculates monthly income (income - expenses, excluding transfers)
//

import Foundation

struct MonthlyIncomeCalculator {

    // MARK: - Result Types

    struct MonthlyResult {
        let netIncome: Decimal
        let totalIncome: Decimal
        let totalExpenses: Decimal
        let month: Date
    }

    struct MonthInfo {
        let displayString: String
        let month: Int
        let year: Int
    }

    // MARK: - Calculation

    /// Calculate net income for a specific month
    /// - Parameters:
    ///   - transactions: List of all transactions
    ///   - month: The month to calculate for
    /// - Returns: MonthlyResult with income, expenses, and net
    static func calculate(transactions: [Transaction], for month: Date) -> MonthlyResult {
        let calendar = Calendar.current
        let monthComponents = calendar.dateComponents([.year, .month], from: month)

        var totalIncome: Decimal = 0
        var totalExpenses: Decimal = 0

        for transaction in transactions {
            // Check if transaction is in the target month
            let txnComponents = calendar.dateComponents([.year, .month], from: transaction.posted)
            guard txnComponents.year == monthComponents.year,
                  txnComponents.month == monthComponents.month else {
                continue
            }

            // Skip transfers
            guard !isTransfer(transaction) else { continue }

            let amount = transaction.amountValue

            if isIncome(transaction) {
                totalIncome += amount
            } else {
                // Expenses are stored as negative, take absolute value
                totalExpenses += abs(amount)
            }
        }

        return MonthlyResult(
            netIncome: totalIncome - totalExpenses,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            month: month
        )
    }

    // MARK: - Classification

    /// Check if a transaction is income (positive amount)
    static func isIncome(_ transaction: Transaction) -> Bool {
        transaction.amountValue > 0
    }

    /// Check if a transaction is a transfer
    static func isTransfer(_ transaction: Transaction) -> Bool {
        guard let category = transaction.category else { return false }
        return category.lowercased() == "transfer"
    }

    // MARK: - Month Navigation

    /// Get display info for a month
    static func monthInfo(for date: Date) -> MonthInfo {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)

        return MonthInfo(
            displayString: formatter.string(from: date),
            month: components.month ?? 1,
            year: components.year ?? 2024
        )
    }

    /// Get the previous month from a given date
    static func previousMonth(from date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: -1, to: date) ?? date
    }

    /// Get the next month from a given date
    static func nextMonth(from date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: 1, to: date) ?? date
    }

    /// Check if a date is in the current month
    static func isCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let nowComponents = calendar.dateComponents([.year, .month], from: now)
        let dateComponents = calendar.dateComponents([.year, .month], from: date)
        return nowComponents.year == dateComponents.year && nowComponents.month == dateComponents.month
    }

    /// Check if a date is in the future
    static func isFutureMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let nowComponents = calendar.dateComponents([.year, .month], from: now)
        let dateComponents = calendar.dateComponents([.year, .month], from: date)

        if let nowYear = nowComponents.year, let dateYear = dateComponents.year,
           let nowMonth = nowComponents.month, let dateMonth = dateComponents.month {
            if dateYear > nowYear { return true }
            if dateYear == nowYear && dateMonth > nowMonth { return true }
        }
        return false
    }
}
