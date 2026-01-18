//
//  AccountDiscoveryView.swift
//  GhostVault
//
//  Account discovery screen (Page 3 of onboarding)
//  Fetches and displays accounts from SimpleFIN
//  Allows users to hide/exclude accounts from totals
//

import SwiftUI
import SwiftData

struct AccountDiscoveryView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var accounts: [DiscoveredAccount] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let simpleFINService = SimpleFINService()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.accent)

                Text("Your Accounts")
                    .font(.title2.bold())

                Text("We found the following accounts. Choose which to include in your totals.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()

            // Content
            if isLoading {
                Spacer()
                ProgressView("Fetching accounts...")
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task {
                            await fetchAccounts()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                Spacer()
            } else {
                accountsList
            }

            // Bottom button
            if !isLoading && errorMessage == nil {
                VStack(spacing: 8) {
                    Text("\(includedAccountsCount) of \(accounts.count) accounts included")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        saveAndContinue()
                    } label: {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .task {
            await fetchAccounts()
        }
    }

    // MARK: - Accounts List

    private var accountsList: some View {
        List {
            ForEach($accounts) { $account in
                AccountRow(account: $account)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var includedAccountsCount: Int {
        accounts.filter { $0.isIncluded }.count
    }

    // MARK: - Data Fetching

    private func fetchAccounts() async {
        isLoading = true
        errorMessage = nil

        do {
            let accountSet = try await simpleFINService.fetchAccounts()

            await MainActor.run {
                accounts = accountSet.accounts.map { apiAccount in
                    DiscoveredAccount(
                        id: apiAccount.id,
                        name: apiAccount.name,
                        organizationName: apiAccount.org?.name ?? "Unknown",
                        type: apiAccount.accountTypeRaw,
                        balance: apiAccount.balance,
                        currency: apiAccount.currency,
                        isIncluded: true
                    )
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    // MARK: - Save and Continue

    private func saveAndContinue() {
        // Save accounts to SwiftData
        for discoveredAccount in accounts {
            let account = Account(
                id: discoveredAccount.id,
                organizationId: nil,
                organizationName: discoveredAccount.organizationName,
                name: discoveredAccount.name,
                currency: discoveredAccount.currency,
                balance: discoveredAccount.balance,
                availableBalance: nil,
                balanceDate: nil,
                accountTypeRaw: discoveredAccount.type,
                isHidden: !discoveredAccount.isIncluded
            )
            modelContext.insert(account)
        }

        try? modelContext.save()
        onContinue()
    }
}

// MARK: - Discovered Account Model

struct DiscoveredAccount: Identifiable {
    let id: String
    let name: String
    let organizationName: String
    let type: String
    let balance: String
    let currency: String
    var isIncluded: Bool
}

// MARK: - Account Row

private struct AccountRow: View {
    @Binding var account: DiscoveredAccount

    var body: some View {
        HStack {
            // Account icon
            Image(systemName: iconForAccountType(account.type))
                .font(.title2)
                .foregroundStyle(.accent)
                .frame(width: 40)

            // Account details
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.headline)

                HStack {
                    Text(account.organizationName)
                    Text("•")
                    Text(account.type.capitalized)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Balance
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatBalance(account.balance, currency: account.currency))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(balanceColor(account.balance))

                // Include toggle
                Toggle("", isOn: $account.isIncluded)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .accent))
            }
        }
        .padding(.vertical, 4)
    }

    private func iconForAccountType(_ type: String) -> String {
        switch type.lowercased() {
        case "checking": return "banknote"
        case "savings": return "dollarsign.circle"
        case "credit card": return "creditcard"
        case "investment": return "chart.line.uptrend.xyaxis"
        case "loan": return "percent"
        case "mortgage": return "house"
        default: return "building.columns"
        }
    }

    private func formatBalance(_ balance: String, currency: String) -> String {
        guard let value = Decimal(string: balance) else { return balance }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: value as NSDecimalNumber) ?? balance
    }

    private func balanceColor(_ balance: String) -> Color {
        guard let value = Decimal(string: balance) else { return .primary }
        return value < 0 ? .red : .primary
    }
}

// MARK: - Account Filtering Logic

struct AccountFilter {
    /// Filters accounts to only include those marked as included
    static func filterIncluded(_ accounts: [DiscoveredAccount]) -> [DiscoveredAccount] {
        accounts.filter { $0.isIncluded }
    }

    /// Calculates total balance of included accounts
    static func totalBalance(_ accounts: [DiscoveredAccount]) -> Decimal {
        accounts
            .filter { $0.isIncluded }
            .compactMap { Decimal(string: $0.balance) }
            .reduce(0, +)
    }

    /// Groups accounts by type
    static func groupByType(_ accounts: [DiscoveredAccount]) -> [String: [DiscoveredAccount]] {
        Dictionary(grouping: accounts) { $0.type }
    }

    /// Filters accounts by organization name
    static func filterByOrganization(_ accounts: [DiscoveredAccount], organization: String) -> [DiscoveredAccount] {
        accounts.filter { $0.organizationName.lowercased().contains(organization.lowercased()) }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AccountDiscoveryView(
            onContinue: { print("Continue") },
            onBack: { print("Back") }
        )
    }
    .modelContainer(for: Account.self, inMemory: true)
}
