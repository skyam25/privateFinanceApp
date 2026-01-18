//
//  DashboardView.swift
//  GhostVault
//
//  Main dashboard showing net worth, monthly income, and sync status
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var syncRateLimiter = SyncRateLimiter()
    @State private var isRefreshing = false

    private let simpleFINService = SimpleFINService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Net Worth card
                    NetWorthCard()

                    // Net Monthly Income card
                    NetMonthlyIncomeCard()

                    Spacer(minLength: 60) // Space for sync bar
                }
                .padding()
            }
            .refreshable {
                await performSync()
            }
            .overlay(alignment: .bottom) {
                // Sync status bar pinned to bottom
                SyncStatusBar(rateLimiter: $syncRateLimiter) {
                    await performSync()
                }
                .background(.regularMaterial)
            }
            .navigationTitle("Dashboard")
        }
        .onAppear {
            syncRateLimiter.checkAndResetIfNeeded()
        }
    }

    // MARK: - Sync Action

    private func performSync() async {
        guard !isRefreshing else { return }

        isRefreshing = true

        do {
            // Get transactions from past month for sync
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)!

            // Fetch accounts and transactions
            _ = try await simpleFINService.fetchAccounts(startDate: startDate, endDate: endDate)

            // TODO: Update SwiftData with fetched data
            // This will be implemented when we integrate with the full sync service

        } catch {
            // Error handling - could show an alert
            print("Sync failed: \(error)")
        }

        isRefreshing = false
    }
}

// MARK: - Preview

#Preview("Dashboard") {
    DashboardView()
        .environmentObject(AppState())
        .modelContainer(previewContainer)
}

#Preview("Empty State") {
    DashboardView()
        .environmentObject(AppState())
        .modelContainer(for: [Account.self, Transaction.self], inMemory: true)
}

// Preview container with sample data
@MainActor
private let previewContainer: ModelContainer = {
    let container = try! ModelContainer(
        for: Account.self, Transaction.self,
        configurations: .init(isStoredInMemoryOnly: true)
    )

    let context = container.mainContext
    let now = Date()
    let calendar = Calendar.current

    // Sample accounts
    context.insert(Account(
        id: "checking1",
        organizationName: "Chase Bank",
        name: "Checking",
        balance: "5432.10",
        accountTypeRaw: "checking"
    ))

    context.insert(Account(
        id: "savings1",
        organizationName: "Chase Bank",
        name: "Savings",
        balance: "25000.00",
        accountTypeRaw: "savings"
    ))

    context.insert(Account(
        id: "cc1",
        organizationName: "Chase Bank",
        name: "Sapphire Reserve",
        balance: "-2345.67",
        accountTypeRaw: "credit card"
    ))

    // Sample transactions for current month
    context.insert(Transaction(
        id: "income1",
        accountId: "checking1",
        posted: now,
        amount: "5000.00",
        transactionDescription: "Payroll",
        category: "Income"
    ))

    context.insert(Transaction(
        id: "expense1",
        accountId: "checking1",
        posted: now,
        amount: "-150.00",
        transactionDescription: "Whole Foods",
        category: "Groceries"
    ))

    context.insert(Transaction(
        id: "expense2",
        accountId: "checking1",
        posted: now,
        amount: "-75.00",
        transactionDescription: "Restaurant",
        category: "Dining"
    ))

    // Last month transaction
    let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
    context.insert(Transaction(
        id: "income2",
        accountId: "checking1",
        posted: lastMonth,
        amount: "5000.00",
        transactionDescription: "Payroll",
        category: "Income"
    ))

    return container
}()
