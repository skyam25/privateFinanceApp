//
//  CategoryDetailView.swift
//  GhostVault
//
//  Category detail view showing transactions and month-over-month comparison
//

import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    @Query private var transactions: [Transaction]

    let categoryName: String
    let categoryColor: Color
    let categoryIcon: String

    @State private var selectedMonth: Date = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Month selector
                monthSelector
                    .padding(.horizontal)

                // Month comparison card
                monthComparisonCard
                    .padding(.horizontal)

                // Transaction list
                transactionList
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        MonthSelectorView(
            selectedMonth: $selectedMonth,
            monthDisplayString: monthDisplayString,
            canGoForward: canGoForward
        )
    }

    // MARK: - Month Comparison Card

    private var monthComparisonCard: some View {
        VStack(spacing: 16) {
            // Category header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: categoryIcon)
                        .font(.title2)
                        .foregroundStyle(categoryColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(categoryName)
                        .font(.headline)
                    Text("\(currentMonthTransactions.count) transaction\(currentMonthTransactions.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(formatCurrency(currentMonthTotal))
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
            }

            Divider()

            // Month-over-month comparison
            HStack(spacing: 24) {
                // Current month
                VStack(spacing: 4) {
                    Text(currentMonthName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatCurrency(currentMonthTotal))
                        .font(.subheadline.bold())
                }

                // Change indicator
                VStack(spacing: 2) {
                    Image(systemName: changeIsPositive ? "arrow.down.right.circle.fill" : "arrow.up.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(changeIsPositive ? .green : .red)

                    Text(formatPercentageChange)
                        .font(.caption.bold())
                        .foregroundStyle(changeIsPositive ? .green : .red)
                }

                // Previous month
                VStack(spacing: 4) {
                    Text(previousMonthName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatCurrency(previousMonthTotal))
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Transaction List

    private var transactionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transactions")
                .font(.headline)
                .padding(.bottom, 4)

            if currentMonthTransactions.isEmpty {
                ContentUnavailableView {
                    Label("No Transactions", systemImage: "list.bullet")
                } description: {
                    Text("No \(categoryName.lowercased()) transactions this month.")
                }
                .frame(height: 150)
            } else {
                ForEach(currentMonthTransactions.sorted { $0.posted > $1.posted }) { transaction in
                    transactionRow(for: transaction)
                }
            }
        }
    }

    private func transactionRow(for transaction: Transaction) -> some View {
        HStack(spacing: 12) {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.posted, format: .dateTime.month(.abbreviated).day())
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(transaction.transactionDescription)
                    .font(.subheadline)
                    .lineLimit(1)
            }

            Spacer()

            // Amount
            Text(formatCurrency(abs(transaction.amountValue)))
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Computed Properties

    private var currentMonthTransactions: [Transaction] {
        filterTransactions(for: selectedMonth)
    }

    private var previousMonthTransactions: [Transaction] {
        let prevMonth = MonthlyIncomeCalculator.previousMonth(from: selectedMonth)
        return filterTransactions(for: prevMonth)
    }

    private func filterTransactions(for month: Date) -> [Transaction] {
        let calendar = Calendar.current
        let monthComponents = calendar.dateComponents([.year, .month], from: month)

        return transactions.filter { transaction in
            let txnComponents = calendar.dateComponents([.year, .month], from: transaction.posted)
            let isThisMonth = txnComponents.year == monthComponents.year && txnComponents.month == monthComponents.month
            let isThisCategory = transaction.category?.lowercased() == categoryName.lowercased()
            let isExpense = transaction.amountValue < 0
            let notIgnored = !transaction.isIgnored

            return isThisMonth && isThisCategory && isExpense && notIgnored
        }
    }

    private var currentMonthTotal: Decimal {
        currentMonthTransactions.reduce(Decimal(0)) { $0 + abs($1.amountValue) }
    }

    private var previousMonthTotal: Decimal {
        previousMonthTransactions.reduce(Decimal(0)) { $0 + abs($1.amountValue) }
    }

    private var monthChange: Decimal {
        currentMonthTotal - previousMonthTotal
    }

    private var percentageChange: Decimal {
        guard previousMonthTotal > 0 else { return 0 }
        return (monthChange / previousMonthTotal) * 100
    }

    private var changeIsPositive: Bool {
        // Less spending is positive (green)
        monthChange <= 0
    }

    private var formatPercentageChange: String {
        let change = abs(percentageChange)
        let prefix = changeIsPositive ? "-" : "+"
        return "\(prefix)\(NSDecimalNumber(decimal: change).doubleValue.formatted(.number.precision(.fractionLength(0...1))))%"
    }

    private var monthDisplayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: selectedMonth)
    }

    private var previousMonthName: String {
        let prevMonth = MonthlyIncomeCalculator.previousMonth(from: selectedMonth)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: prevMonth)
    }

    private var canGoForward: Bool {
        !MonthlyIncomeCalculator.isFutureMonth(MonthlyIncomeCalculator.nextMonth(from: selectedMonth))
    }

    // MARK: - Formatting

    private func formatCurrency(_ value: Decimal) -> String {
        CurrencyFormatter.format(value)
    }
}

// MARK: - Preview

#Preview("With Data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Transaction.self, configurations: config)

    let context = container.mainContext
    let calendar = Calendar.current
    let now = Date()

    // Current month transactions
    let currentMonthExpenses: [(String, String)] = [
        ("-45.00", "CHIPOTLE MEXICAN GRILL"),
        ("-25.00", "PANERA BREAD"),
        ("-85.00", "OLIVE GARDEN"),
        ("-15.00", "STARBUCKS"),
        ("-55.00", "CHEESECAKE FACTORY"),
    ]

    for (index, expense) in currentMonthExpenses.enumerated() {
        let transaction = Transaction(
            id: "cur\(index)",
            accountId: "checking",
            posted: calendar.date(byAdding: .day, value: -index * 5, to: now)!,
            amount: expense.0,
            transactionDescription: expense.1,
            category: "Dining"
        )
        context.insert(transaction)
    }

    // Last month transactions
    let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
    let lastMonthExpenses: [(String, String)] = [
        ("-65.00", "OLIVE GARDEN"),
        ("-35.00", "PANERA BREAD"),
        ("-95.00", "RUTH'S CHRIS"),
    ]

    for (index, expense) in lastMonthExpenses.enumerated() {
        let transaction = Transaction(
            id: "prev\(index)",
            accountId: "checking",
            posted: calendar.date(byAdding: .day, value: -index * 7, to: lastMonth)!,
            amount: expense.0,
            transactionDescription: expense.1,
            category: "Dining"
        )
        context.insert(transaction)
    }

    return NavigationStack {
        CategoryDetailView(
            categoryName: "Dining",
            categoryColor: .orange,
            categoryIcon: "fork.knife"
        )
    }
    .modelContainer(container)
}

#Preview("Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Transaction.self, configurations: config)

    return NavigationStack {
        CategoryDetailView(
            categoryName: "Travel",
            categoryColor: .cyan,
            categoryIcon: "airplane"
        )
    }
    .modelContainer(container)
}
