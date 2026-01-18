//
//  GhostVaultApp.swift
//  GhostVault
//
//  Local-First Private Finance Tracker
//  Your data stays on your device. Always.
//

import SwiftUI
import SwiftData

@main
struct GhostVaultApp: App {
    @StateObject private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
            Transaction.self,
            Organization.self,
            Category.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.ghostvault.app")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - App State
@MainActor
class AppState: ObservableObject {
    @Published var isOnboarded: Bool {
        didSet {
            UserDefaults.standard.set(isOnboarded, forKey: "isOnboarded")
        }
    }

    @Published var hasSimpleFINToken: Bool = false
    @Published var lastSyncDate: Date?
    @Published var isSyncing: Bool = false

    private let keychainService = KeychainService()

    init() {
        self.isOnboarded = UserDefaults.standard.bool(forKey: "isOnboarded")
        self.hasSimpleFINToken = keychainService.hasAccessURL()
        self.lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    }

    func checkSimpleFINConnection() {
        hasSimpleFINToken = keychainService.hasAccessURL()
    }

    func setLastSyncDate(_ date: Date) {
        lastSyncDate = date
        UserDefaults.standard.set(date, forKey: "lastSyncDate")
    }
}
