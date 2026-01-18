//
//  NetWorthCard.swift
//  GhostVault
//
//  Dashboard card showing total net worth with delta indicator
//

import SwiftUI
import SwiftData

struct NetWorthCard: View {
    @Query(filter: #Predicate<Account> { !$0.isHidden })
    private var accounts: [Account]

    @State private var isExpanded = false
    @State private var previousNetWorth: Decimal? = nil
    @State private var showChart = false

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                mainCardContent
            }
            .buttonStyle(.plain)

            // Expanded breakdown
            if isExpanded {
                Divider()
                    .padding(.horizontal)

                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    // MARK: - Main Card Content

    private var mainCardContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Net Worth")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(formattedNetWorth)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                deltaIndicator
            }

            Spacer()

            // Expand/collapse indicator
            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                .font(.title2)
                .foregroundStyle(.accent)
        }
    }

    // MARK: - Delta Indicator

    @ViewBuilder
    private var deltaIndicator: some View {
        if let previous = previousNetWorth {
            let delta = NetWorthCalculator.calculateDelta(current: netWorthResult.netWorth, previous: previous)

            HStack(spacing: 4) {
                Image(systemName: delta.isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption.bold())

                Text(formatCurrency(abs(delta.amount)))
                    .font(.caption)

                if let percentage = delta.percentageChange {
                    Text("(\(formatPercentage(percentage)))")
                        .font(.caption)
                }
            }
            .foregroundStyle(delta.isPositive ? .green : .red)
        } else {
            Text("—")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: 12) {
            // Assets row
            HStack {
                Label("Assets", systemImage: "arrow.up.circle.fill")
                    .foregroundStyle(.green)
                Spacer()
                Text(formatCurrency(netWorthResult.totalAssets))
                    .fontWeight(.medium)
            }

            // Liabilities row
            HStack {
                Label("Liabilities", systemImage: "arrow.down.circle.fill")
                    .foregroundStyle(.red)
                Spacer()
                Text(formatCurrency(netWorthResult.totalLiabilities))
                    .fontWeight(.medium)
            }

            Divider()

            // Account counts
            HStack {
                Text("\(assetAccounts.count) asset account\(assetAccounts.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(liabilityAccounts.count) liability account\(liabilityAccounts.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.vertical, 8)

            // View Trend Chart button
            Button {
                showChart = true
            } label: {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("View Trend Chart")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 12)
        .font(.subheadline)
        .navigationDestination(isPresented: $showChart) {
            NetWorthChartView()
        }
    }

    // MARK: - Computed Properties

    private var netWorthResult: NetWorthCalculator.NetWorthResult {
        NetWorthCalculator.calculate(accounts: accounts)
    }

    private var formattedNetWorth: String {
        formatCurrency(netWorthResult.netWorth)
    }

    private var assetAccounts: [Account] {
        accounts.filter { NetWorthCalculator.isAssetType($0.accountType) }
    }

    private var liabilityAccounts: [Account] {
        accounts.filter { !NetWorthCalculator.isAssetType($0.accountType) }
    }

    // MARK: - Formatting Helpers

    private func formatCurrency(_ value: Decimal) -> String {
        CurrencyFormatter.format(value)
    }

    private func formatPercentage(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        formatter.multiplier = 0.01 // Value is already a percentage
        return formatter.string(from: value as NSDecimalNumber) ?? "0%"
    }
}

// MARK: - Preview

#Preview("With Data") {
    NetWorthCard()
        .padding()
        .modelContainer(previewContainer)
}

#Preview("Empty") {
    NetWorthCard()
        .padding()
        .modelContainer(for: Account.self, inMemory: true)
}

// Preview helper container with sample data
@MainActor
private let previewContainer: ModelContainer = {
    let container = try! ModelContainer(for: Account.self, configurations: .init(isStoredInMemoryOnly: true))

    let context = container.mainContext

    // Sample asset accounts
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
        id: "investment1",
        organizationName: "Fidelity",
        name: "401k",
        balance: "150000.00",
        accountTypeRaw: "investment"
    ))

    // Sample liability accounts
    context.insert(Account(
        id: "cc1",
        organizationName: "Chase Bank",
        name: "Sapphire Reserve",
        balance: "-2345.67",
        accountTypeRaw: "credit card"
    ))

    context.insert(Account(
        id: "mortgage1",
        organizationName: "Wells Fargo",
        name: "Home Mortgage",
        balance: "-285000.00",
        accountTypeRaw: "mortgage"
    ))

    return container
}()
