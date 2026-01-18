//
//  DailySnapshot.swift
//  GhostVault
//
//  SwiftData model for daily net worth snapshots
//

import Foundation
import SwiftData

/// A snapshot of net worth metrics for a specific date
@Model
final class DailySnapshot {
    @Attribute(.unique) var date: Date
    var netWorth: String // Store as string for precision
    var totalAssets: String
    var totalLiabilities: String

    // Computed properties for decimal values
    var netWorthValue: Decimal {
        Decimal(string: netWorth) ?? 0
    }

    var totalAssetsValue: Decimal {
        Decimal(string: totalAssets) ?? 0
    }

    var totalLiabilitiesValue: Decimal {
        Decimal(string: totalLiabilities) ?? 0
    }

    init(
        date: Date,
        netWorth: String,
        totalAssets: String,
        totalLiabilities: String
    ) {
        // Normalize date to start of day for uniqueness
        self.date = Calendar.current.startOfDay(for: date)
        self.netWorth = netWorth
        self.totalAssets = totalAssets
        self.totalLiabilities = totalLiabilities
    }

    /// Create a snapshot from account values
    convenience init(date: Date, assets: Decimal, liabilities: Decimal) {
        let netWorth = assets + liabilities // liabilities are already negative
        self.init(
            date: date,
            netWorth: "\(netWorth)",
            totalAssets: "\(assets)",
            totalLiabilities: "\(liabilities)"
        )
    }
}

// MARK: - Snapshot Manager

/// Utility for creating and managing daily snapshots
struct DailySnapshotManager {

    /// Create or update a daily snapshot from current accounts
    /// - Parameters:
    ///   - accounts: All accounts to include
    ///   - modelContext: SwiftData context for persistence
    /// - Returns: The created or updated snapshot
    @discardableResult
    static func createSnapshot(from accounts: [Account], in modelContext: ModelContext) -> DailySnapshot {
        let calculator = NetWorthCalculator.calculate(accounts: accounts)

        let snapshot = DailySnapshot(
            date: Date(),
            assets: calculator.totalAssets,
            liabilities: calculator.totalLiabilities
        )
        // Set liabilities as negative for consistent storage
        snapshot.totalLiabilities = "\(-calculator.totalLiabilities)"

        modelContext.insert(snapshot)
        return snapshot
    }

    /// Get snapshots for a date range
    /// - Parameters:
    ///   - start: Start date (inclusive)
    ///   - end: End date (inclusive)
    ///   - modelContext: SwiftData context
    /// - Returns: Array of snapshots sorted by date
    static func snapshots(from start: Date, to end: Date, in modelContext: ModelContext) throws -> [DailySnapshot] {
        let startOfDay = Calendar.current.startOfDay(for: start)
        let endOfDay = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: end)!)

        let predicate = #Predicate<DailySnapshot> { snapshot in
            snapshot.date >= startOfDay && snapshot.date < endOfDay
        }

        let descriptor = FetchDescriptor<DailySnapshot>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Get the most recent snapshot
    static func latestSnapshot(in modelContext: ModelContext) throws -> DailySnapshot? {
        var descriptor = FetchDescriptor<DailySnapshot>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first
    }

    /// Calculate net worth change between two dates
    static func netWorthChange(from start: Date, to end: Date, in modelContext: ModelContext) throws -> Decimal? {
        let snapshots = try snapshots(from: start, to: end, in: modelContext)
        guard let first = snapshots.first, let last = snapshots.last else {
            return nil
        }
        return last.netWorthValue - first.netWorthValue
    }
}
