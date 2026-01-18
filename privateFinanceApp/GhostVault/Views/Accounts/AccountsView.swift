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

    // MARK: - Grouping

    private var groupedAccounts: [(key: String, value: [Account])] {
        let grouped = Dictionary(grouping: accounts) { account in
            account.organizationName ?? "Unknown Institution"
        }
        return grouped.sorted { $0.key < $1.key }
    }

    // MARK: - Formatting

    private func formatGroupBalance(_ accounts: [Account]) -> String {
        let total = accounts
            .filter { !$0.isHidden }
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

                    if account.isHidden {
                        Text("• Hidden")
                            .font(.caption)
                            .foregroundStyle(.orange)
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
        // Placeholder for delta - will be implemented in P3-T2
        nil
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
