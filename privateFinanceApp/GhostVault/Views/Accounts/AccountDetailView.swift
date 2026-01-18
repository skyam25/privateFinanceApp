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
            Label("Hide from Totals", systemImage: "eye.slash")
        }
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

// MARK: - Transaction Row View

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: transaction.categoryIcon)
                    .font(.subheadline)
                    .foregroundStyle(categoryColor)
            }

            // Description and date
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.payee ?? transaction.transactionDescription)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(transaction.posted, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedAmount)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(amountColor)

                if transaction.pending {
                    Text("Pending")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"

        let value = transaction.amountValue
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }

    private var amountColor: Color {
        transaction.amountValue >= 0 ? .green : .primary
    }

    private var categoryColor: Color {
        switch transaction.category?.lowercased() {
        case "income", "salary":
            return .green
        case "transfer":
            return .blue
        case "food", "dining", "restaurants", "food & dining":
            return .orange
        case "shopping":
            return .purple
        case "groceries":
            return .teal
        default:
            return .gray
        }
    }
}

// MARK: - Account Transactions List View

struct AccountTransactionsListView: View {
    let accountId: String
    let accountName: String

    @Query private var transactions: [Transaction]

    init(accountId: String, accountName: String) {
        self.accountId = accountId
        self.accountName = accountName
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
            ForEach(transactions) { transaction in
                TransactionRowView(transaction: transaction)
            }
        }
        .listStyle(.plain)
        .navigationTitle(accountName)
        .navigationBarTitleDisplayMode(.inline)
    }
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

    // Add sample transactions
    let transactions = [
        Transaction(
            id: "t1",
            accountId: "1",
            posted: Date().addingTimeInterval(-86400),
            amount: "-45.50",
            transactionDescription: "TRADER JOES",
            payee: "Trader Joe's",
            category: "Groceries"
        ),
        Transaction(
            id: "t2",
            accountId: "1",
            posted: Date().addingTimeInterval(-172800),
            amount: "-120.00",
            transactionDescription: "AMAZON",
            payee: "Amazon",
            category: "Shopping"
        ),
        Transaction(
            id: "t3",
            accountId: "1",
            posted: Date().addingTimeInterval(-259200),
            amount: "2500.00",
            transactionDescription: "PAYROLL DEPOSIT",
            payee: "Payroll",
            category: "Income"
        ),
        Transaction(
            id: "t4",
            accountId: "1",
            posted: Date().addingTimeInterval(-345600),
            amount: "-35.00",
            transactionDescription: "CHIPOTLE",
            payee: "Chipotle",
            category: "Dining"
        )
    ]

    for txn in transactions {
        container.mainContext.insert(txn)
    }

    return NavigationStack {
        AccountDetailView(account: account)
    }
    .modelContainer(container)
}

#Preview("Credit Card Detail") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Account.self, Transaction.self, configurations: config)

    let account = Account(
        id: "2",
        organizationName: "Chase Bank",
        name: "Freedom Card ****9012",
        currency: "USD",
        balance: "-1250.50",
        accountTypeRaw: "credit card",
        previousBalance: "-1100.00",
        lastSyncDate: Date().addingTimeInterval(-7200)
    )
    container.mainContext.insert(account)

    return NavigationStack {
        AccountDetailView(account: account)
    }
    .modelContainer(container)
}

#Preview("Empty Transactions") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Account.self, Transaction.self, configurations: config)

    let account = Account(
        id: "3",
        organizationName: "Fidelity",
        name: "401(k)",
        currency: "USD",
        balance: "125000.00",
        accountTypeRaw: "investment"
    )
    container.mainContext.insert(account)

    return NavigationStack {
        AccountDetailView(account: account)
    }
    .modelContainer(container)
}
