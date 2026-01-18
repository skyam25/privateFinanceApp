//
//  AccountBalanceDelta.swift
//  GhostVault
//
//  Calculates balance changes for individual accounts
//

import Foundation

struct AccountBalanceDelta {

    // MARK: - Result Type

    struct Delta {
        let amount: Decimal
        let isPositive: Bool
        let percentageChange: Decimal?

        var isZero: Bool {
            amount == 0
        }
    }

    // MARK: - Calculation

    /// Calculate the delta between current and previous balance
    /// - Parameters:
    ///   - current: Current balance value
    ///   - previous: Previous balance value (optional)
    /// - Returns: Delta if previous balance exists, nil otherwise
    static func calculate(current: Decimal, previous: Decimal?) -> Delta? {
        guard let previousValue = previous else { return nil }
        return calculateDelta(current: current, previous: previousValue)
    }

    /// Calculate delta from an Account's current and previous balance
    /// - Parameter account: The account to calculate delta for
    /// - Returns: Delta if account has previous balance, nil otherwise
    static func calculate(for account: Account) -> Delta? {
        guard let previousValue = account.previousBalanceValue else { return nil }
        return calculateDelta(current: account.balanceValue, previous: previousValue)
    }

    // MARK: - Private

    private static func calculateDelta(current: Decimal, previous: Decimal) -> Delta {
        let amount = current - previous
        let isPositive = amount >= 0

        let percentageChange: Decimal?
        if previous == 0 {
            // Avoid division by zero
            percentageChange = nil
        } else {
            percentageChange = (amount / previous) * 100
        }

        return Delta(
            amount: amount,
            isPositive: isPositive,
            percentageChange: percentageChange
        )
    }

    // MARK: - Formatting

    /// Format delta amount as a currency string with +/- prefix
    static func formatDelta(_ delta: Delta, currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode

        let formattedAmount = formatter.string(from: abs(delta.amount) as NSDecimalNumber) ?? "$0.00"
        let prefix = delta.isPositive ? "+" : "-"

        return "\(prefix)\(formattedAmount)"
    }

    /// Format delta as percentage string
    static func formatPercentage(_ delta: Delta) -> String? {
        guard let percentage = delta.percentageChange else { return nil }

        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1

        let absPercentage = abs(percentage)
        // Divide by 100 since percent style expects decimal form (e.g., 0.5 for 50%)
        if let formatted = formatter.string(from: (absPercentage / 100) as NSDecimalNumber) {
            let prefix = delta.isPositive ? "+" : "-"
            return "\(prefix)\(formatted)"
        }
        return nil
    }
}
