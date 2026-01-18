//
//  CategoryBreakdownView.swift
//  GhostVault
//
//  Category breakdown donut chart with expense distribution
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Category Data Point

struct CategoryDataPoint: Identifiable {
    let id = UUID()
    let name: String
    let amount: Decimal
    let percentage: Double
    let color: Color
    let icon: String
}

// MARK: - Category Breakdown View

struct CategoryBreakdownView: View {
    @Query private var transactions: [Transaction]

    @State private var selectedMonth: Date = Date()
    @State private var selectedCategory: CategoryDataPoint?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Month selector
                monthSelector
                    .padding(.horizontal)

                if categoryData.isEmpty {
                    emptyStateView
                } else {
                    // Donut chart
                    donutChartSection
                        .padding(.horizontal)

                    // Category list
                    categoryListSection
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Spending by Category")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        HStack {
            Button {
                withAnimation {
                    selectedMonth = MonthlyIncomeCalculator.previousMonth(from: selectedMonth)
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.accent)
            }

            Spacer()

            Text(monthDisplayString)
                .font(.headline)

            Spacer()

            Button {
                withAnimation {
                    selectedMonth = MonthlyIncomeCalculator.nextMonth(from: selectedMonth)
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canGoForward ? .accent : .secondary.opacity(0.3))
            }
            .disabled(!canGoForward)
        }
    }

    // MARK: - Donut Chart Section

    private var donutChartSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Donut chart
                Chart(categoryData) { category in
                    SectorMark(
                        angle: .value("Amount", NSDecimalNumber(decimal: category.amount).doubleValue),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(category.color)
                    .opacity(selectedCategory == nil || selectedCategory?.id == category.id ? 1.0 : 0.5)
                }
                .frame(height: 250)

                // Center total
                VStack(spacing: 4) {
                    Text("Total Expenses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatCurrency(totalExpenses))
                        .font(.title2.bold())
                }
            }

            // Selected category info
            if let selected = selectedCategory {
                selectedCategoryCard(for: selected)
            }
        }
    }

    private func selectedCategoryCard(for category: CategoryDataPoint) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(category.color)
            }

            // Name and amount
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.headline)
                Text("\(formatCurrency(category.amount))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Percentage
            Text(String(format: "%.1f%%", category.percentage))
                .font(.title3.bold())
                .foregroundStyle(category.color)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Category List Section

    private var categoryListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(categoryData.sorted { $0.amount > $1.amount }) { category in
                categoryRow(for: category)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            if selectedCategory?.id == category.id {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                        }
                    }
            }
        }
    }

    private func categoryRow(for category: CategoryDataPoint) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: category.icon)
                    .font(.subheadline)
                    .foregroundStyle(category.color)
            }

            // Name
            Text(category.name)
                .font(.subheadline)

            Spacer()

            // Amount and percentage
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(category.amount))
                    .font(.subheadline.bold())
                Text(String(format: "%.1f%%", category.percentage))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            selectedCategory?.id == category.id
                ? category.color.opacity(0.1)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Expenses", systemImage: "chart.pie")
        } description: {
            Text("No expense transactions found for this month.")
        }
        .frame(height: 300)
    }

    // MARK: - Computed Properties

    private var categoryData: [CategoryDataPoint] {
        let calendar = Calendar.current
        let monthComponents = calendar.dateComponents([.year, .month], from: selectedMonth)

        // Filter to expenses only (negative amounts, excluding transfers and income)
        let monthlyExpenses = transactions.filter { transaction in
            let txnComponents = calendar.dateComponents([.year, .month], from: transaction.posted)
            let isThisMonth = txnComponents.year == monthComponents.year && txnComponents.month == monthComponents.month
            let isExpense = transaction.amountValue < 0
            let notTransfer = transaction.category?.lowercased() != "transfer"
            let notIncome = !["income", "salary", "payroll"].contains(transaction.category?.lowercased() ?? "")
            let notIgnored = !transaction.isIgnored

            return isThisMonth && isExpense && notTransfer && notIncome && notIgnored
        }

        // Group by category
        var categoryTotals: [String: Decimal] = [:]
        for transaction in monthlyExpenses {
            let category = transaction.category ?? "Uncategorized"
            let amount = abs(transaction.amountValue)
            categoryTotals[category, default: 0] += amount
        }

        // Calculate total for percentages
        let total = categoryTotals.values.reduce(Decimal(0), +)
        guard total > 0 else { return [] }

        // Convert to data points
        return categoryTotals.map { name, amount in
            let percentage = (NSDecimalNumber(decimal: amount / total).doubleValue) * 100
            return CategoryDataPoint(
                name: name.capitalized,
                amount: amount,
                percentage: percentage,
                color: categoryColor(for: name),
                icon: TransactionCategory.icon(for: name)
            )
        }
    }

    private var totalExpenses: Decimal {
        categoryData.reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var monthDisplayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private var canGoForward: Bool {
        !MonthlyIncomeCalculator.isFutureMonth(MonthlyIncomeCalculator.nextMonth(from: selectedMonth))
    }

    // MARK: - Helper Functions

    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "food & dining", "food", "dining", "restaurants":
            return .orange
        case "shopping":
            return .purple
        case "transportation", "auto", "gas":
            return .blue
        case "bills & utilities", "bills", "utilities":
            return .yellow
        case "entertainment":
            return .pink
        case "health & fitness", "health", "medical":
            return .red
        case "travel":
            return .cyan
        case "groceries":
            return .teal
        case "subscriptions":
            return .indigo
        default:
            return .gray
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
}

// MARK: - Preview

#Preview("With Data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Transaction.self, configurations: config)

    let context = container.mainContext
    let now = Date()

    // Sample expense transactions
    let expenses: [(String, String, String)] = [
        ("-150.00", "Whole Foods", "Groceries"),
        ("-85.00", "Trader Joe's", "Groceries"),
        ("-45.00", "Chipotle", "Dining"),
        ("-65.00", "Olive Garden", "Dining"),
        ("-120.00", "Target", "Shopping"),
        ("-200.00", "Nordstrom", "Shopping"),
        ("-75.00", "Amazon", "Shopping"),
        ("-50.00", "Shell Gas", "Transportation"),
        ("-35.00", "Uber", "Transportation"),
        ("-120.00", "Electric Company", "Bills & Utilities"),
        ("-80.00", "Netflix + Spotify", "Subscriptions"),
        ("-60.00", "Gym Membership", "Health & Fitness"),
    ]

    for (index, expense) in expenses.enumerated() {
        let transaction = Transaction(
            id: "exp\(index)",
            accountId: "checking",
            posted: now.addingTimeInterval(TimeInterval(-86400 * index)),
            amount: expense.0,
            transactionDescription: expense.1,
            payee: expense.1,
            category: expense.2
        )
        context.insert(transaction)
    }

    return NavigationStack {
        CategoryBreakdownView()
    }
    .modelContainer(container)
}

#Preview("Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Transaction.self, configurations: config)

    return NavigationStack {
        CategoryBreakdownView()
    }
    .modelContainer(container)
}
