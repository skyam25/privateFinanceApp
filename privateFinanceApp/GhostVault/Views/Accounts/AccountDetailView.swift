//
//  AccountDetailView.swift
//  GhostVault
//
//  Account detail view with balance, sparkline, transactions, and settings
//

import SwiftUI
import SwiftData
import Charts

struct AccountDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var account: Account

    @Query private var transactions: [Transaction]

    @State private var isEditingNickname = false
    @State private var nicknameText = ""

    init(account: Account) {
        self.account = account
        // Filter transactions for this account
        let accountId = account.id
        _transactions = Query(
            filter: #Predicate<Transaction> { transaction in
                transaction.accountId == accountId
            },
            sort: \Transaction.posted,
            order: .reverse
        )
    }

    var body: some View {
        List {
            // Balance section
            Section {
                balanceCard
            }

            // Sparkline section
            if !transactions.isEmpty {
                Section {
                    balanceSparkline
                } header: {
                    Text("Balance Trend")
                }
            }

            // Transactions section
            Section {
                if transactions.isEmpty {
                    ContentUnavailableView {
                        Label("No Transactions", systemImage: "list.bullet")
                    } description: {
                        Text("Transactions will appear here after sync")
                    }
                } else {
                    ForEach(recentTransactions) { transaction in
                        TransactionRowView(transaction: transaction)
                    }

                    if transactions.count > 10 {
                        NavigationLink {
                            AccountTransactionsListView(
                                accountId: account.id,
                                accountName: account.displayName
                            )
                        } label: {
                            Text("See All \(transactions.count) Transactions")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            } header: {
                Text("Recent Transactions")
            }

            // Settings section
            Section {
                nicknameRow
                trackingOnlyRow
                hideToggleRow
            } header: {
                Text("Account Settings")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(account.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            nicknameText = account.nickname ?? ""
        }
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        VStack(alignment: .center, spacing: 12) {
            // Account type icon
            ZStack {
                Circle()
                    .fill(account.accountType.color.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: account.accountType.iconName)
                    .font(.title)
                    .foregroundStyle(account.accountType.color)
            }

            // Current balance
            Text(formattedBalance)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(balanceColor)

            // Delta since last sync
            if let delta = AccountBalanceDelta.calculate(for: account) {
                HStack(spacing: 4) {
                    Image(systemName: delta.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)

                    Text(AccountBalanceDelta.formatDelta(delta, currencyCode: account.currency ?? "USD"))
                        .font(.subheadline.monospacedDigit())

                    if let percentage = AccountBalanceDelta.formatPercentage(delta) {
                        Text("(\(percentage))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("since last sync")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(delta.isPositive ? .green : .red)
            }

            // Last sync time
            if let lastSync = account.lastSyncDate {
                Text("Last synced \(lastSync, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Account type label
            Text(account.accountType.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Sparkline

    private var balanceSparkline: some View {
        let dataPoints = sparklineData

        return Chart(dataPoints, id: \.date) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Balance", point.balance)
            )
            .foregroundStyle(balanceColor.gradient)

            AreaMark(
                x: .value("Date", point.date),
                y: .value("Balance", point.balance)
            )
            .foregroundStyle(balanceColor.opacity(0.1).gradient)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 100)
    }

    private var sparklineData: [BalanceDataPoint] {
        // Generate sparkline data from transactions
        // Start from oldest transaction and accumulate balance changes
        let sortedTransactions = transactions.sorted { $0.posted < $1.posted }

        guard !sortedTransactions.isEmpty else { return [] }

        var dataPoints: [BalanceDataPoint] = []
        var runningBalance = account.balanceValue

        // Work backwards from current balance using transactions
        // This is a simplified approach - in Phase 6 we'll use DailySnapshot
        let today = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: today) ?? today

        // Get transactions from last 30 days
        let recentTxns = sortedTransactions.filter { $0.posted >= thirtyDaysAgo }

        if recentTxns.isEmpty {
            // No recent transactions, show flat line
            return [
                BalanceDataPoint(date: thirtyDaysAgo, balance: runningBalance),
                BalanceDataPoint(date: today, balance: runningBalance)
            ]
        }

        // Start with current balance at today
        dataPoints.append(BalanceDataPoint(date: today, balance: runningBalance))

        // Work backwards through transactions to reconstruct historical balances
        for transaction in recentTxns.reversed() {
            // Subtract the transaction to get prior balance
            runningBalance -= transaction.amountValue
            dataPoints.append(BalanceDataPoint(date: transaction.posted, balance: runningBalance))
        }

        // Reverse to chronological order
        return dataPoints.reversed()
    }

    // MARK: - Transaction Rows

    private var recentTransactions: [Transaction] {
        Array(transactions.prefix(10))
    }

    // MARK: - Settings Rows

    private var nicknameRow: some View {
        HStack {
            Label("Nickname", systemImage: "pencil")

            Spacer()

            if isEditingNickname {
                TextField("Enter nickname", text: $nicknameText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 150)
                    .onSubmit {
                        saveNickname()
                    }

                Button("Done") {
                    saveNickname()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Text(account.nickname ?? "None")
                    .foregroundStyle(.secondary)

                Button {
                    isEditingNickname = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private var hideToggleRow: some View {
        Toggle(isOn: $account.isHidden) {
            VStack(alignment: .leading, spacing: 2) {
                Label("Hidden", systemImage: "eye.slash")
                Text("Completely hide from all views")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var trackingOnlyRow: some View {
        Toggle(isOn: $account.trackingOnly) {
            VStack(alignment: .leading, spacing: 2) {
                Label("Tracking Only", systemImage: "chart.bar.doc.horizontal")
                Text("Show in list but exclude from totals")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(account.isHidden) // Can't be tracking only if hidden
    }

    // MARK: - Helpers

    private func saveNickname() {
        let trimmed = nicknameText.trimmingCharacters(in: .whitespacesAndNewlines)
        account.nickname = trimmed.isEmpty ? nil : trimmed
        isEditingNickname = false
    }

    private var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = account.currency ?? "USD"

        let value = isLiability ? abs(account.balanceValue) : account.balanceValue
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }

    private var balanceColor: Color {
        if isLiability {
            return .red
        }
        return account.balanceValue >= 0 ? .green : .red
    }

    private var isLiability: Bool {
        switch account.accountType {
        case .creditCard, .loan, .mortgage:
            return true
        default:
            return false
        }
    }
}

// MARK: - Balance Data Point

struct BalanceDataPoint {
    let date: Date
    let balance: Decimal
}

// MARK: - Preview

#Preview("Account Detail") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Account.self, Transaction.self, configurations: config)

    let account = Account(
        id: "1",
        organizationName: "Chase Bank",
        name: "Checking ****1234",
        currency: "USD",
        balance: "5432.10",
        accountTypeRaw: "checking",
        previousBalance: "5000.00",
        lastSyncDate: Date().addingTimeInterval(-3600)
    )
    container.mainContext.insert(account)

    return NavigationStack {
        AccountDetailView(account: account)
    }
    .modelContainer(container)
}
