//
//  NetMonthlyIncomeCard.swift
//  GhostVault
//
//  Dashboard card showing net monthly income with month selector
//

import SwiftUI
import SwiftData

struct NetMonthlyIncomeCard: View {
    @Query private var transactions: [Transaction]

    @State private var selectedMonth: Date = Date()
    @State private var isExpanded = false

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
        .gesture(monthSwipeGesture)
    }

    // MARK: - Main Card Content

    private var mainCardContent: some View {
        VStack(spacing: 12) {
            // Month selector
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

                Text(monthInfo.displayString)
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

            // Net income display
            VStack(spacing: 4) {
                Text("Net Income")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(formattedNetIncome)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(netIncomeColor)
            }

            // Expand indicator
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: 12) {
            // Income row
            HStack {
                Label("Income", systemImage: "arrow.down.circle.fill")
                    .foregroundStyle(.green)
                Spacer()
                Text(formatCurrency(monthlyResult.totalIncome))
                    .fontWeight(.medium)
                    .foregroundStyle(.green)
            }

            // Expenses row
            HStack {
                Label("Expenses", systemImage: "arrow.up.circle.fill")
                    .foregroundStyle(.red)
                Spacer()
                Text(formatCurrency(monthlyResult.totalExpenses))
                    .fontWeight(.medium)
                    .foregroundStyle(.red)
            }

            Divider()

            // Transaction count
            HStack {
                Text("\(transactionCount) transaction\(transactionCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if isCurrentMonth {
                    Label("Current month", systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.accent)
                }
            }
        }
        .padding(.top, 12)
        .font(.subheadline)
    }

    // MARK: - Swipe Gesture

    private var monthSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height

                // Only respond to horizontal swipes
                guard abs(horizontal) > abs(vertical) else { return }

                withAnimation {
                    if horizontal > 0 {
                        // Swipe right = previous month
                        selectedMonth = MonthlyIncomeCalculator.previousMonth(from: selectedMonth)
                    } else if horizontal < 0 && canGoForward {
                        // Swipe left = next month
                        selectedMonth = MonthlyIncomeCalculator.nextMonth(from: selectedMonth)
                    }
                }
            }
    }

    // MARK: - Computed Properties

    private var monthlyResult: MonthlyIncomeCalculator.MonthlyResult {
        MonthlyIncomeCalculator.calculate(transactions: transactions, for: selectedMonth)
    }

    private var monthInfo: MonthlyIncomeCalculator.MonthInfo {
        MonthlyIncomeCalculator.monthInfo(for: selectedMonth)
    }

    private var formattedNetIncome: String {
        formatCurrency(monthlyResult.netIncome)
    }

    private var netIncomeColor: Color {
        if monthlyResult.netIncome > 0 {
            return .green
        } else if monthlyResult.netIncome < 0 {
            return .red
        } else {
            return .primary
        }
    }

    private var canGoForward: Bool {
        !MonthlyIncomeCalculator.isFutureMonth(MonthlyIncomeCalculator.nextMonth(from: selectedMonth))
    }

    private var isCurrentMonth: Bool {
        MonthlyIncomeCalculator.isCurrentMonth(selectedMonth)
    }

    private var transactionCount: Int {
        let calendar = Calendar.current
        let monthComponents = calendar.dateComponents([.year, .month], from: selectedMonth)

        return transactions.filter { transaction in
            let txnComponents = calendar.dateComponents([.year, .month], from: transaction.posted)
            return txnComponents.year == monthComponents.year && txnComponents.month == monthComponents.month
        }.count
    }

    // MARK: - Formatting Helpers

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
    NetMonthlyIncomeCard()
        .padding()
        .modelContainer(previewContainer)
}

#Preview("Empty") {
    NetMonthlyIncomeCard()
        .padding()
        .modelContainer(for: Transaction.self, inMemory: true)
}

// Preview helper container with sample data
@MainActor
private let previewContainer: ModelContainer = {
    let container = try! ModelContainer(for: Transaction.self, configurations: .init(isStoredInMemoryOnly: true))

    let context = container.mainContext
    let calendar = Calendar.current
    let now = Date()

    // Current month transactions
    context.insert(Transaction(
        id: "income1",
        accountId: "checking",
        posted: now,
        amount: "5000.00",
        transactionDescription: "Payroll",
        category: "Income"
    ))

    context.insert(Transaction(
        id: "expense1",
        accountId: "checking",
        posted: now,
        amount: "-150.00",
        transactionDescription: "Grocery Store",
        category: "Groceries"
    ))

    context.insert(Transaction(
        id: "expense2",
        accountId: "checking",
        posted: now,
        amount: "-75.00",
        transactionDescription: "Restaurant",
        category: "Dining"
    ))

    context.insert(Transaction(
        id: "transfer1",
        accountId: "checking",
        posted: now,
        amount: "-500.00",
        transactionDescription: "Transfer to Savings",
        category: "Transfer"
    ))

    // Last month transactions
    let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!

    context.insert(Transaction(
        id: "income2",
        accountId: "checking",
        posted: lastMonth,
        amount: "5000.00",
        transactionDescription: "Payroll",
        category: "Income"
    ))

    context.insert(Transaction(
        id: "expense3",
        accountId: "checking",
        posted: lastMonth,
        amount: "-200.00",
        transactionDescription: "Shopping",
        category: "Shopping"
    ))

    return container
}()
