//
//  TransactionsView.swift
//  GhostVault
//
//  Transaction list with date headers and classification badges
//

import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.posted, order: .reverse) private var transactions: [Transaction]
    @Query private var accounts: [Account]

    @State private var selectedTransaction: Transaction?
    @State private var searchText = ""
    @State private var selectedQuickFilter: TransactionFilter.QuickFilter = .all
    @State private var showFilterSheet = false
    @State private var filterOptions = TransactionFilter.Options()

    private var filteredTransactions: [Transaction] {
        var options = filterOptions
        options.searchText = searchText
        options.quickFilter = selectedQuickFilter
        return TransactionFilter.apply(options, to: transactions)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !transactions.isEmpty {
                    quickFilterPills
                }

                Group {
                    if transactions.isEmpty {
                        emptyState
                    } else if filteredTransactions.isEmpty {
                        noResultsState
                    } else {
                        transactionsList
                    }
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $searchText, prompt: "Search transactions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: filterOptions.isEmpty ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                }
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailSheet(transaction: transaction)
            }
            .sheet(isPresented: $showFilterSheet) {
                TransactionFilterSheet(
                    options: $filterOptions,
                    accounts: accounts
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        NoTransactionsEmptyState()
    }

    // MARK: - No Results State

    private var noResultsState: some View {
        NoTransactionsEmptyState(isFiltered: true) {
            searchText = ""
            selectedQuickFilter = .all
            filterOptions = TransactionFilter.Options()
        }
    }

    // MARK: - Quick Filter Pills

    private var quickFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TransactionFilter.QuickFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedQuickFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedQuickFilter == filter ? Color.accentColor : Color(.systemGray5))
                            )
                            .foregroundStyle(selectedQuickFilter == filter ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Transactions List

    private var transactionsList: some View {
        List {
            // Pending transactions section at top
            if !pendingTransactions.isEmpty {
                Section {
                    ForEach(pendingTransactions) { transaction in
                        Button {
                            selectedTransaction = transaction
                        } label: {
                            TransactionListRowView(transaction: transaction)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundStyle(.orange.opacity(0.5))
                                .background(Color(.systemBackground))
                        )
                    }
                } header: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.orange)
                        Text("Pending")
                            .foregroundStyle(.orange)
                    }
                }
            }

            // Grouped by date
            ForEach(groupedTransactions, id: \.key) { group in
                Section {
                    ForEach(group.value) { transaction in
                        Button {
                            selectedTransaction = transaction
                        } label: {
                            TransactionListRowView(transaction: transaction)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(formatDateHeader(group.key))
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Grouping

    private var pendingTransactions: [Transaction] {
        filteredTransactions.filter { $0.pending }
    }

    private var groupedTransactions: [(key: Date, value: [Transaction])] {
        // Filter out pending transactions (shown in separate section)
        let postedTransactions = filteredTransactions.filter { !$0.pending }

        // Group by date (ignoring time component)
        let grouped = Dictionary(grouping: postedTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.posted)
        }

        // Sort by date descending
        return grouped.sorted { $0.key > $1.key }
    }

    // MARK: - Formatting

    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            // This week - show day name
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            // This year - show month and day
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: date)
        } else {
            // Different year - show full date
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// MARK: - Transaction List Row View

struct TransactionListRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Classification badge icon
            ZStack {
                Circle()
                    .fill(transaction.classificationType.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: transaction.classificationType.iconName)
                    .font(.title3)
                    .foregroundStyle(transaction.classificationType.color)
            }

            // Transaction details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.payee ?? transaction.transactionDescription)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    // Classification badge
                    Text(transaction.classificationType.displayName)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(transaction.classificationType.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(transaction.classificationType.color.opacity(0.1))
                        .clipShape(Capsule())

                    // Classification reason
                    if let reason = transaction.classificationReason {
                        Text(reason)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedAmount)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(amountColor)

                if transaction.pending {
                    Text("Pending")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var formattedAmount: String {
        CurrencyFormatter.format(transaction.amountValue, maximumFractionDigits: 2)
    }

    private var amountColor: Color {
        if transaction.isIgnored {
            return .secondary
        }
        return transaction.amountValue >= 0 ? .green : .primary
    }
}

// MARK: - Preview

#Preview("With Transactions") {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Transaction.self, configurations: config)

        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -5, to: today)!

        Task { @MainActor in
            container.mainContext.insert(Transaction(
                id: "t1", accountId: "acc1", posted: today, amount: "-45.99",
                transactionDescription: "AMAZON MARKETPLACE", payee: "Amazon",
                pending: true, category: "Shopping", classificationReason: "Default"
            ))
            container.mainContext.insert(Transaction(
                id: "t2", accountId: "acc1", posted: today, amount: "-12.50",
                transactionDescription: "STARBUCKS #12345", payee: "Starbucks",
                category: "Dining", classificationReason: "Default"
            ))
            container.mainContext.insert(Transaction(
                id: "t3", accountId: "acc1", posted: today, amount: "2500.00",
                transactionDescription: "PAYROLL DEPOSIT ACME INC", payee: "ACME Inc",
                category: "Income", classificationReason: "Payee Rule: Payroll"
            ))
            container.mainContext.insert(Transaction(
                id: "t4", accountId: "acc1", posted: yesterday, amount: "-150.00",
                transactionDescription: "TRANSFER TO SAVINGS", payee: "Transfer",
                category: "Transfer", classificationReason: "Auto-Transfer"
            ))
            container.mainContext.insert(Transaction(
                id: "t5", accountId: "acc1", posted: yesterday, amount: "-85.32",
                transactionDescription: "TRADER JOES #123", payee: "Trader Joe's",
                category: "Groceries", classificationReason: "Default"
            ))
            container.mainContext.insert(Transaction(
                id: "t6", accountId: "acc1", posted: lastWeek, amount: "-25.00",
                transactionDescription: "VENMO PAYMENT", payee: "Venmo",
                classificationReason: "Manual", isIgnored: true
            ))
            container.mainContext.insert(Transaction(
                id: "t7", accountId: "acc1", posted: lastWeek, amount: "-199.99",
                transactionDescription: "APPLE.COM/BILL", payee: "Apple",
                category: "Subscriptions", classificationReason: "Default"
            ))
        }
        return container
    }()

    TransactionsView()
        .modelContainer(container)
}

#Preview("Empty State") {
    TransactionsView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
