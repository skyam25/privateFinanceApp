//
//  MonthlySnapshot.swift
//  GhostVault
//
//  SwiftData model for monthly income/expense snapshots
//

import Foundation
import SwiftData

/// A snapshot of income and expense metrics for a specific month
@Model
final class MonthlySnapshot {
    var year: Int
    var month: Int
    var totalIncome: String // Store as string for precision
    var totalExpenses: String // Stored as positive value
    var netIncome: String

    // Computed properties for decimal values
    var totalIncomeValue: Decimal {
        Decimal(string: totalIncome) ?? 0
    }

    var totalExpensesValue: Decimal {
        Decimal(string: totalExpenses) ?? 0
    }

    var netIncomeValue: Decimal {
        Decimal(string: netIncome) ?? 0
    }

    /// Create a unique key for this snapshot
    var key: String {
        "\(year)-\(String(format: "%02d", month))"
    }

    /// Get the date representing the first of this month
    var date: Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
    }

    init(
        year: Int,
        month: Int,
        totalIncome: String,
        totalExpenses: String,
        netIncome: String
    ) {
        self.year = year
        self.month = month
        self.totalIncome = totalIncome
        self.totalExpenses = totalExpenses
        self.netIncome = netIncome
    }

    /// Create a snapshot from calculated values
    convenience init(year: Int, month: Int, income: Decimal, expenses: Decimal) {
        let netIncome = income - expenses
        self.init(
            year: year,
            month: month,
            totalIncome: "\(income)",
            totalExpenses: "\(expenses)",
            netIncome: "\(netIncome)"
        )
    }
}

// MARK: - Snapshot Manager

/// Utility for creating and managing monthly snapshots
struct MonthlySnapshotManager {

    /// Create or update a monthly snapshot from transactions
    /// - Parameters:
    ///   - transactions: Transactions for the month
    ///   - year: Year of the snapshot
    ///   - month: Month of the snapshot (1-12)
    ///   - modelContext: SwiftData context for persistence
    /// - Returns: The created or updated snapshot
    @discardableResult
    static func createSnapshot(
        from transactions: [Transaction],
        year: Int,
        month: Int,
        in modelContext: ModelContext
    ) -> MonthlySnapshot {
        // Filter transactions for this month
        let filteredTransactions = transactions.filter { transaction in
            let components = Calendar.current.dateComponents([.year, .month], from: transaction.posted)
            return components.year == year && components.month == month
        }

        // Calculate income and expenses
        let referenceDate = Calendar.current.date(from: DateComponents(year: year, month: month, day: 15))!
        let calculator = MonthlyIncomeCalculator.calculate(
            transactions: filteredTransactions,
            for: referenceDate
        )

        let snapshot = MonthlySnapshot(
            year: year,
            month: month,
            income: calculator.totalIncome,
            expenses: calculator.totalExpenses
        )

        modelContext.insert(snapshot)
        return snapshot
    }

    /// Create a monthly snapshot from pre-calculated values
    @discardableResult
    static func createSnapshot(
        year: Int,
        month: Int,
        income: Decimal,
        expenses: Decimal,
        in modelContext: ModelContext
    ) -> MonthlySnapshot {
        let snapshot = MonthlySnapshot(
            year: year,
            month: month,
            income: income,
            expenses: expenses
        )

        modelContext.insert(snapshot)
        return snapshot
    }

    /// Get snapshots for a date range
    /// - Parameters:
    ///   - startYear: Start year
    ///   - startMonth: Start month
    ///   - endYear: End year
    ///   - endMonth: End month
    ///   - modelContext: SwiftData context
    /// - Returns: Array of snapshots sorted by date
    static func snapshots(
        from startYear: Int,
        startMonth: Int,
        to endYear: Int,
        endMonth: Int,
        in modelContext: ModelContext
    ) throws -> [MonthlySnapshot] {
        let startKey = startYear * 100 + startMonth
        let endKey = endYear * 100 + endMonth

        let predicate = #Predicate<MonthlySnapshot> { snapshot in
            (snapshot.year * 100 + snapshot.month) >= startKey &&
            (snapshot.year * 100 + snapshot.month) <= endKey
        }

        let descriptor = FetchDescriptor<MonthlySnapshot>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.year), SortDescriptor(\.month)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Get all monthly snapshots sorted by date
    static func allSnapshots(in modelContext: ModelContext) throws -> [MonthlySnapshot] {
        let descriptor = FetchDescriptor<MonthlySnapshot>(
            sortBy: [SortDescriptor(\.year), SortDescriptor(\.month)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Get the most recent monthly snapshot
    static func latestSnapshot(in modelContext: ModelContext) throws -> MonthlySnapshot? {
        let descriptor = FetchDescriptor<MonthlySnapshot>(
            sortBy: [SortDescriptor(\.year, order: .reverse), SortDescriptor(\.month, order: .reverse)]
        )

        return try modelContext.fetch(descriptor).first
    }

    /// Calculate average monthly net income over a period
    static func averageNetIncome(in modelContext: ModelContext) throws -> Decimal? {
        let snapshots = try allSnapshots(in: modelContext)
        guard !snapshots.isEmpty else { return nil }

        let total = snapshots.reduce(Decimal(0)) { $0 + $1.netIncomeValue }
        return total / Decimal(snapshots.count)
    }
}
