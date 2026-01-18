//
//  TransactionFilter.swift
//  GhostVault
//
//  Filter utility for transactions with search and quick filters
//

import Foundation

struct TransactionFilter {

    // MARK: - Filter Options

    struct Options {
        var searchText: String = ""
        var accountIds: Set<String> = []
        var classificationTypes: Set<ClassificationType> = []
        var dateRange: DateRange = .all
        var quickFilter: QuickFilter = .all

        var isEmpty: Bool {
            searchText.isEmpty &&
            accountIds.isEmpty &&
            classificationTypes.isEmpty &&
            dateRange == .all &&
            quickFilter == .all
        }
    }

    enum DateRange: Equatable {
        case all
        case thisMonth
        case lastMonth
        case custom(start: Date, end: Date)

        static func == (lhs: DateRange, rhs: DateRange) -> Bool {
            switch (lhs, rhs) {
            case (.all, .all): return true
            case (.thisMonth, .thisMonth): return true
            case (.lastMonth, .lastMonth): return true
            case let (.custom(s1, e1), .custom(s2, e2)):
                return s1 == s2 && e1 == e2
            default: return false
            }
        }

        func dateRange() -> (start: Date, end: Date)? {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .all:
                return nil
            case .thisMonth:
                let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
                return (start, end)
            case .lastMonth:
                let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                let start = calendar.date(byAdding: .month, value: -1, to: thisMonth)!
                let end = calendar.date(byAdding: .day, value: -1, to: thisMonth)!
                return (start, end)
            case let .custom(start, end):
                return (start, end)
            }
        }
    }

    enum QuickFilter: String, CaseIterable {
        case all = "All"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case incomeOnly = "Income"
        case expensesOnly = "Expenses"
    }

    // MARK: - Filtering

    /// Apply all filters to a list of transactions
    static func apply(_ options: Options, to transactions: [Transaction]) -> [Transaction] {
        var result = transactions

        // Apply search text filter
        if !options.searchText.isEmpty {
            result = searchFilter(text: options.searchText, in: result)
        }

        // Apply account filter
        if !options.accountIds.isEmpty {
            result = result.filter { options.accountIds.contains($0.accountId) }
        }

        // Apply classification filter
        if !options.classificationTypes.isEmpty {
            result = result.filter { options.classificationTypes.contains($0.classificationType) }
        }

        // Apply date range filter
        if let range = options.dateRange.dateRange() {
            result = result.filter { $0.posted >= range.start && $0.posted <= range.end }
        }

        // Apply quick filter
        result = applyQuickFilter(options.quickFilter, to: result)

        return result
    }

    /// Search transactions by payee, description, or amount
    static func searchFilter(text: String, in transactions: [Transaction]) -> [Transaction] {
        let searchText = text.lowercased().trimmingCharacters(in: .whitespaces)
        guard !searchText.isEmpty else { return transactions }

        return transactions.filter { transaction in
            // Search in payee
            if let payee = transaction.payee?.lowercased(), payee.contains(searchText) {
                return true
            }

            // Search in description
            if transaction.transactionDescription.lowercased().contains(searchText) {
                return true
            }

            // Search in amount (as string)
            if transaction.amount.contains(searchText) {
                return true
            }

            // Search by formatted amount
            let formattedAmount = String(format: "%.2f", NSDecimalNumber(decimal: transaction.amountValue).doubleValue)
            if formattedAmount.contains(searchText) {
                return true
            }

            // Search in category
            if let category = transaction.category?.lowercased(), category.contains(searchText) {
                return true
            }

            return false
        }
    }

    /// Apply quick filter preset
    static func applyQuickFilter(_ filter: QuickFilter, to transactions: [Transaction]) -> [Transaction] {
        switch filter {
        case .all:
            return transactions
        case .thisMonth:
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return transactions.filter { $0.posted >= startOfMonth }
        case .lastMonth:
            let calendar = Calendar.current
            let now = Date()
            let startOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfThisMonth)!
            return transactions.filter { $0.posted >= startOfLastMonth && $0.posted < startOfThisMonth }
        case .incomeOnly:
            return transactions.filter { $0.classificationType == .income }
        case .expensesOnly:
            return transactions.filter { $0.classificationType == .expense }
        }
    }

    // MARK: - Filtering by Account

    static func filterByAccount(_ accountId: String, in transactions: [Transaction]) -> [Transaction] {
        transactions.filter { $0.accountId == accountId }
    }

    // MARK: - Filtering by Classification

    static func filterByClassification(_ type: ClassificationType, in transactions: [Transaction]) -> [Transaction] {
        transactions.filter { $0.classificationType == type }
    }

    // MARK: - Filtering by Date Range

    static func filterByDateRange(start: Date, end: Date, in transactions: [Transaction]) -> [Transaction] {
        transactions.filter { $0.posted >= start && $0.posted <= end }
    }

    // MARK: - Combined Filters

    static func filterByMultipleClassifications(
        _ types: Set<ClassificationType>,
        in transactions: [Transaction]
    ) -> [Transaction] {
        guard !types.isEmpty else { return transactions }
        return transactions.filter { types.contains($0.classificationType) }
    }

    static func filterByMultipleAccounts(
        _ accountIds: Set<String>,
        in transactions: [Transaction]
    ) -> [Transaction] {
        guard !accountIds.isEmpty else { return transactions }
        return transactions.filter { accountIds.contains($0.accountId) }
    }
}
