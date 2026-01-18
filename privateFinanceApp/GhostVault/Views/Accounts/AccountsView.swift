//
//  AccountsView.swift
//  GhostVault
//
//  Account list grouped by institution
//

import SwiftUI
import SwiftData

struct AccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.organizationName) private var accounts: [Account]
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            Group {
                if accounts.isEmpty {
                    emptyState
                } else {
                    accountsList
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .environment(\.editMode, $editMode)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Accounts", systemImage: "building.columns")
        } description: {
            Text("Connect to SimpleFIN to see your accounts")
        }
    }

    // MARK: - Accounts List

    private var accountsList: some View {
        List {
            ForEach(groupedAccounts, id: \.key) { group in
                Section {
                    ForEach(group.value) { account in
                        NavigationLink(value: account) {
                            AccountRowView(account: account)
                        }
                    }
                    .onMove { from, to in
                        moveAccounts(in: group.key, from: from, to: to)
                    }
                } header: {
                    HStack {
                        Text(group.key)
                        Spacer()
                        Text(formatGroupBalance(group.value))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(for: Account.self) { account in
            AccountDetailView(account: account)
        }
    }

    // MARK: - Reordering

    private func moveAccounts(in groupKey: String, from source: IndexSet, to destination: Int) {
        // Get accounts for this group, sorted by displayOrder
        var groupAccounts = accounts
            .filter { ($0.organizationName ?? "Unknown Institution") == groupKey }
            .sorted { $0.displayOrder < $1.displayOrder }

        // Perform the move
        groupAccounts.move(fromOffsets: source, toOffset: destination)

        // Update displayOrder for all accounts in the group
        for (index, account) in groupAccounts.enumerated() {
            account.displayOrder = index
        }
    }

    // MARK: - Grouping

    private var groupedAccounts: [(key: String, value: [Account])] {
        // Filter out hidden accounts from the list view
        let visibleAccounts = accounts.filter { !$0.isHidden }

        let grouped = Dictionary(grouping: visibleAccounts) { account in
            account.organizationName ?? "Unknown Institution"
        }

        // Sort groups alphabetically, and accounts within groups by displayOrder
        return grouped
            .map { (key: $0.key, value: $0.value.sorted { $0.displayOrder < $1.displayOrder }) }
            .sorted { $0.key < $1.key }
    }

    // MARK: - Formatting

    private func formatGroupBalance(_ accounts: [Account]) -> String {
        let total = accounts
            .filter { !$0.isExcludedFromTotals }
            .reduce(Decimal.zero) { $0 + $1.balanceValue }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: total as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Account Row View

struct AccountRowView: View {
    let account: Account

    var body: some View {
        HStack(spacing: 12) {
            // Account type icon with color indicator
            ZStack {
                Circle()
                    .fill(balanceColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: account.accountType.iconName)
                    .font(.title3)
                    .foregroundStyle(balanceColor)
            }

            // Account details
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(account.accountType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if account.trackingOnly {
                        Text("• Tracking")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }

            Spacer()

            // Balance
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedBalance)
                    .font(.subheadline.monospacedDigit().bold())
                    .foregroundStyle(balanceColor)

                if let delta = deltaSinceLastSync {
                    Text(delta)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Computed Properties

    private var balanceColor: Color {
        if isLiability {
            return .red
        } else {
            return account.balanceValue >= 0 ? .green : .red
        }
    }

    private var isLiability: Bool {
        switch account.accountType {
        case .creditCard, .loan, .mortgage:
            return true
        default:
            return false
        }
    }

    private var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = account.currency ?? "USD"

        // For liabilities, show absolute value with negative indicator
        let value = isLiability ? abs(account.balanceValue) : account.balanceValue
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }

    private var deltaSinceLastSync: String? {
        guard let delta = AccountBalanceDelta.calculate(for: account),
              !delta.isZero else { return nil }
        return AccountBalanceDelta.formatDelta(delta, currencyCode: account.currency ?? "USD")
    }
}

// MARK: - Preview

#Preview("With Accounts") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Account.self, configurations: config)

    // Sample accounts
    let accounts = [
        Account(
            id: "1",
            organizationName: "Chase Bank",
            name: "Checking ****1234",
            currency: "USD",
            balance: "5432.10",
            accountTypeRaw: "checking"
        ),
        Account(
            id: "2",
            organizationName: "Chase Bank",
            name: "Savings ****5678",
            currency: "USD",
            balance: "15000.00",
            accountTypeRaw: "savings"
        ),
        Account(
            id: "3",
            organizationName: "Chase Bank",
            name: "Freedom Card ****9012",
            currency: "USD",
            balance: "-1250.50",
            accountTypeRaw: "credit card"
        ),
        Account(
            id: "4",
            organizationName: "Fidelity",
            name: "401(k)",
            currency: "USD",
            balance: "125000.00",
            accountTypeRaw: "investment"
        ),
        Account(
            id: "5",
            organizationName: "Fidelity",
            name: "Roth IRA",
            currency: "USD",
            balance: "45000.00",
            accountTypeRaw: "investment"
        ),
        Account(
            id: "6",
            organizationName: "Bank of America",
            name: "Auto Loan",
            currency: "USD",
            balance: "-18500.00",
            accountTypeRaw: "loan"
        )
    ]

    for account in accounts {
        container.mainContext.insert(account)
    }

    return AccountsView()
        .modelContainer(container)
}

#Preview("Empty State") {
    AccountsView()
        .modelContainer(for: Account.self, inMemory: true)
}
