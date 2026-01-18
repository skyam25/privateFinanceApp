//
//  NetWorthCalculator.swift
//  GhostVault
//
//  Calculates net worth from accounts (assets - liabilities)
//

import Foundation

struct NetWorthCalculator {

    // MARK: - Result Types

    struct NetWorthResult {
        let netWorth: Decimal
        let totalAssets: Decimal
        let totalLiabilities: Decimal
    }

    struct Delta {
        let amount: Decimal
        let isPositive: Bool
        let percentageChange: Decimal?
    }

    // MARK: - Calculation

    /// Calculate net worth from a list of accounts
    /// - Parameter accounts: List of Account objects
    /// - Returns: NetWorthResult with total net worth, assets, and liabilities
    static func calculate(accounts: [Account]) -> NetWorthResult {
        var totalAssets: Decimal = 0
        var totalLiabilities: Decimal = 0

        for account in accounts {
            // Skip hidden accounts
            guard !account.isHidden else { continue }

            let balance = account.balanceValue

            if isAssetType(account.accountType) {
                // For asset accounts, positive balance adds to assets
                if balance >= 0 {
                    totalAssets += balance
                } else {
                    // Negative balance in asset account (overdraft) is liability
                    totalLiabilities += abs(balance)
                }
            } else {
                // For liability accounts (credit card, loan, mortgage)
                // Balance is typically stored as negative, we take absolute value
                totalLiabilities += abs(balance)
            }
        }

        let netWorth = totalAssets - totalLiabilities

        return NetWorthResult(
            netWorth: netWorth,
            totalAssets: totalAssets,
            totalLiabilities: totalLiabilities
        )
    }

    // MARK: - Delta Calculation

    /// Calculate the change between current and previous net worth
    static func calculateDelta(current: Decimal, previous: Decimal) -> Delta {
        let amount = current - previous
        let isPositive = amount >= 0

        let percentageChange: Decimal?
        if previous == 0 {
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

    // MARK: - Account Classification

    /// Determine if an account type is an asset (vs liability)
    static func isAssetType(_ type: AccountType) -> Bool {
        switch type {
        case .checking, .savings, .investment, .unknown:
            return true
        case .creditCard, .loan, .mortgage:
            return false
        }
    }
}
