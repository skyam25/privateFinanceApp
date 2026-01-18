//
//  SyncRateLimiterTests.swift
//  GhostVaultTests
//
//  Unit tests for sync rate limit tracking logic
//

import XCTest
@testable import GhostVault

final class SyncRateLimiterTests: XCTestCase {

    // MARK: - Basic Rate Limiting

    func testInitialStateHasMaximumSyncsAvailable() {
        let limiter = SyncRateLimiter()

        XCTAssertEqual(limiter.remainingSyncs, 24)
        XCTAssertTrue(limiter.canSync)
    }

    func testRecordingSyncDecrementsCount() {
        var limiter = SyncRateLimiter()

        limiter.recordSync()

        XCTAssertEqual(limiter.remainingSyncs, 23)
    }

    func testMultipleSyncsDecrementCorrectly() {
        var limiter = SyncRateLimiter()

        limiter.recordSync()
        limiter.recordSync()
        limiter.recordSync()

        XCTAssertEqual(limiter.remainingSyncs, 21)
    }

    func testCannotSyncWhenLimitExhausted() {
        var limiter = SyncRateLimiter()

        // Exhaust all syncs
        for _ in 0..<24 {
            limiter.recordSync()
        }

        XCTAssertEqual(limiter.remainingSyncs, 0)
        XCTAssertFalse(limiter.canSync)
    }

    // MARK: - Reset Logic

    func testSyncsResetAfter24Hours() {
        var limiter = SyncRateLimiter()

        // Use some syncs
        limiter.recordSync()
        limiter.recordSync()

        // Simulate 24 hours passing
        let pastDate = Calendar.current.date(byAdding: .hour, value: -25, to: Date())!
        limiter.lastResetDate = pastDate

        // Check should trigger reset
        limiter.checkAndResetIfNeeded()

        XCTAssertEqual(limiter.remainingSyncs, 24)
    }

    func testSyncsDoNotResetBefore24Hours() {
        var limiter = SyncRateLimiter()

        // Use some syncs
        limiter.recordSync()
        limiter.recordSync()

        // Simulate 12 hours passing (less than 24)
        let pastDate = Calendar.current.date(byAdding: .hour, value: -12, to: Date())!
        limiter.lastResetDate = pastDate

        limiter.checkAndResetIfNeeded()

        XCTAssertEqual(limiter.remainingSyncs, 22)
    }

    // MARK: - Time Until Reset

    func testTimeUntilResetWhenFullyAvailable() {
        let limiter = SyncRateLimiter()

        // Should be nil or 24 hours from now when just initialized
        let timeUntilReset = limiter.timeUntilReset

        XCTAssertNotNil(timeUntilReset)
        // Should be close to 24 hours
        XCTAssertGreaterThan(timeUntilReset!, 23 * 60 * 60) // > 23 hours
        XCTAssertLessThanOrEqual(timeUntilReset!, 24 * 60 * 60) // <= 24 hours
    }

    func testTimeUntilResetWhenExhausted() {
        var limiter = SyncRateLimiter()

        // Exhaust all syncs
        for _ in 0..<24 {
            limiter.recordSync()
        }

        let timeUntilReset = limiter.timeUntilReset

        XCTAssertNotNil(timeUntilReset)
        XCTAssertGreaterThan(timeUntilReset!, 0)
    }

    // MARK: - Last Sync Tracking

    func testLastSyncTimeUpdatesOnSync() {
        var limiter = SyncRateLimiter()
        let beforeSync = Date()

        limiter.recordSync()

        XCTAssertNotNil(limiter.lastSyncTime)
        XCTAssertGreaterThanOrEqual(limiter.lastSyncTime!, beforeSync)
    }

    func testTimeSinceLastSyncWhenNeverSynced() {
        let limiter = SyncRateLimiter()

        XCTAssertNil(limiter.lastSyncTime)
        XCTAssertNil(limiter.timeSinceLastSync)
    }

    func testTimeSinceLastSyncAfterSync() {
        var limiter = SyncRateLimiter()

        limiter.recordSync()

        // Should be very recent (within a second)
        XCTAssertNotNil(limiter.timeSinceLastSync)
        XCTAssertLessThan(limiter.timeSinceLastSync!, 1.0)
    }

    // MARK: - Persistence Helpers

    func testSyncHistoryCountMatchesSyncsUsed() {
        var limiter = SyncRateLimiter()

        limiter.recordSync()
        limiter.recordSync()
        limiter.recordSync()

        XCTAssertEqual(limiter.syncsUsedToday, 3)
    }

    // MARK: - Formatting

    func testFormattedLastSyncTimeWhenNeverSynced() {
        let limiter = SyncRateLimiter()

        XCTAssertEqual(limiter.formattedLastSyncTime, "Never")
    }

    func testFormattedLastSyncTimeWhenRecent() {
        var limiter = SyncRateLimiter()
        limiter.recordSync()

        // Should say something like "Just now" or show recent time
        let formatted = limiter.formattedLastSyncTime
        XCTAssertNotEqual(formatted, "Never")
    }

    func testFormattedRemainingSyncs() {
        var limiter = SyncRateLimiter()

        XCTAssertEqual(limiter.formattedRemainingSyncs, "24/24")

        limiter.recordSync()
        limiter.recordSync()

        XCTAssertEqual(limiter.formattedRemainingSyncs, "22/24")
    }

    // MARK: - Edge Cases

    func testRecordingSyncWhenExhaustedDoesNotGoNegative() {
        var limiter = SyncRateLimiter()

        // Exhaust all syncs
        for _ in 0..<24 {
            limiter.recordSync()
        }

        // Try to sync again
        limiter.recordSync()

        XCTAssertEqual(limiter.remainingSyncs, 0)
        XCTAssertFalse(limiter.canSync)
    }

    func testResetSetsNewResetDate() {
        var limiter = SyncRateLimiter()

        // Set reset date to past
        let pastDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        limiter.lastResetDate = pastDate

        limiter.checkAndResetIfNeeded()

        // Reset date should now be recent
        let hoursSinceReset = limiter.lastResetDate.timeIntervalSinceNow / 3600
        XCTAssertGreaterThan(hoursSinceReset, -1) // Within last hour
    }
}
