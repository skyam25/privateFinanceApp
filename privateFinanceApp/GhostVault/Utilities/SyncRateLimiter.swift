//
//  SyncRateLimiter.swift
//  GhostVault
//
//  Tracks sync rate limits (24 syncs per 24 hours for SimpleFIN)
//

import Foundation

struct SyncRateLimiter {

    // MARK: - Constants

    static let maxDailySyncs = 24
    static let resetIntervalSeconds: TimeInterval = 24 * 60 * 60 // 24 hours

    // MARK: - Properties

    var remainingSyncs: Int
    var lastResetDate: Date
    var lastSyncTime: Date?
    private(set) var syncTimes: [Date]

    // MARK: - Initialization

    init() {
        self.remainingSyncs = Self.maxDailySyncs
        self.lastResetDate = Date()
        self.lastSyncTime = nil
        self.syncTimes = []
    }

    // MARK: - Computed Properties

    var canSync: Bool {
        remainingSyncs > 0
    }

    var syncsUsedToday: Int {
        Self.maxDailySyncs - remainingSyncs
    }

    var timeSinceLastSync: TimeInterval? {
        guard let lastSync = lastSyncTime else { return nil }
        return Date().timeIntervalSince(lastSync)
    }

    var timeUntilReset: TimeInterval? {
        let resetTime = lastResetDate.addingTimeInterval(Self.resetIntervalSeconds)
        let remaining = resetTime.timeIntervalSince(Date())
        return remaining > 0 ? remaining : nil
    }

    // MARK: - Formatting

    var formattedLastSyncTime: String {
        guard let lastSync = lastSyncTime else { return "Never" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastSync, relativeTo: Date())
    }

    var formattedRemainingSyncs: String {
        "\(remainingSyncs)/\(Self.maxDailySyncs)"
    }

    var formattedTimeUntilReset: String? {
        guard let seconds = timeUntilReset else { return nil }

        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Actions

    mutating func recordSync() {
        guard canSync else { return }

        remainingSyncs -= 1
        lastSyncTime = Date()
        syncTimes.append(Date())
    }

    mutating func checkAndResetIfNeeded() {
        let timeSinceReset = Date().timeIntervalSince(lastResetDate)

        if timeSinceReset >= Self.resetIntervalSeconds {
            reset()
        }
    }

    mutating func reset() {
        remainingSyncs = Self.maxDailySyncs
        lastResetDate = Date()
        syncTimes.removeAll()
    }
}
