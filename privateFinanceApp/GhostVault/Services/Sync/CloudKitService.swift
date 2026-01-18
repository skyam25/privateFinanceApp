//
//  CloudKitService.swift
//  GhostVault
//
//  CloudKit sync service - uses SwiftData's built-in CloudKit support
//  Data syncs to user's private iCloud container automatically
//

import Foundation
import CloudKit

// MARK: - CloudKit Service
// Note: Primary sync is handled by SwiftData's CloudKit integration
// This service is for additional CloudKit operations if needed

class CloudKitService {
    private let container = CKContainer(identifier: "iCloud.com.ghostvault.app")

    // MARK: - Account Status

    func checkAccountStatus() async throws -> CKAccountStatus {
        try await container.accountStatus()
    }

    // MARK: - Sync Status
    // TODO: Implement sync status monitoring if needed

    func isICloudAvailable() async -> Bool {
        do {
            let status = try await checkAccountStatus()
            return status == .available
        } catch {
            return false
        }
    }
}
