//
//  IncomeExpenseChartView.swift
//  GhostVault
//
//  Net monthly income bar chart with income vs expenses and net income views
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Chart View Mode

enum IncomeExpenseViewMode: String, CaseIterable, Identifiable {
    case incomeVsExpenses = "Income vs Expenses"
    case netIncome = "Net Income"

    var id: String { rawValue }
}

// MARK: - Monthly Data Point

struct MonthlyDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let monthLabel: String
    let income: Decimal
    let expenses: Decimal
    let netIncome: Decimal
}

// MARK: - Bar Chart Data

struct BarChartEntry: Identifiable {
    let id = UUID()
    let monthLabel: String
    let category: String
    let value: Double
}

// MARK: - Income Expense Chart View

struct IncomeExpenseChartView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var snapshots: [MonthlySnapshot]

    @State private var viewMode: IncomeExpenseViewMode = .incomeVsExpenses
    @State private var selectedTimeframe: ChartTimeframe = .oneYear
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()
    @State private var showCustomDatePicker = false
    @State private var selectedMonth: MonthlyDataPoint?

    var body: some View {
        VStack(spacing: 0) {
            // View mode toggle
            viewModeToggle
                .padding(.horizontal)
                .padding(.bottom, 8)

            // Timeframe selector
            timeframeSelector
                .padding(.horizontal)
                .padding(.bottom, 8)

            if filteredDataPoints.isEmpty {
                emptyStateView
            } else {
                // Chart
                chartView
                    .padding(.horizontal)

                // Summary
                summaryView
                    .padding()
            }

            Spacer()
        }
        .navigationTitle("Income & Expenses")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCustomDatePicker) {
            CustomDatePickerSheet(
                customStartDate: $customStartDate,
                customEndDate: $customEndDate,
                selectedTimeframe: $selectedTimeframe,
                isPresented: $showCustomDatePicker
            )
        }
    }

    // MARK: - View Mode Toggle

    private var viewModeToggle: some View {
        Picker("View Mode", selection: $viewMode) {
            ForEach(IncomeExpenseViewMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Timeframe Selector

    private var timeframeSelector: some View {
        TimeframeSelectorView(
            selectedTimeframe: $selectedTimeframe,
            showCustomDatePicker: $showCustomDatePicker
        )
    }

    // MARK: - Chart View

    @ViewBuilder
    private var chartView: some View {
        switch viewMode {
        case .incomeVsExpenses:
            incomeVsExpensesChart
        case .netIncome:
            netIncomeChart
        }
    }

    private var incomeVsExpensesChart: some View {
        let entries = barChartEntries

        return Chart(entries) { entry in
            BarMark(
                x: .value("Month", entry.monthLabel),
                y: .value("Amount", entry.value)
            )
            .foregroundStyle(by: .value("Category", entry.category))
            .position(by: .value("Category", entry.category))
        }
        .chartForegroundStyleScale([
            "Income": Color.green,
            "Expenses": Color.red
        ])
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                if let doubleValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text(formatCurrencyCompact(Decimal(doubleValue)))
                    }
                }
                AxisGridLine()
            }
        }
        .chartLegend(position: .top)
        .frame(height: 280)
    }

    private var netIncomeChart: some View {
        let dataPoints = filteredDataPoints

        return Chart(dataPoints) { point in
            BarMark(
                x: .value("Month", point.monthLabel),
                y: .value("Net Income", NSDecimalNumber(decimal: point.netIncome).doubleValue)
            )
            .foregroundStyle(point.netIncome >= 0 ? Color.green : Color.red)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                if let doubleValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text(formatCurrencyCompact(Decimal(doubleValue)))
                    }
                }
                AxisGridLine()
            }
        }
        .frame(height: 280)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Data", systemImage: "chart.bar")
        } description: {
            Text("Monthly snapshots will appear here after syncing your accounts.")
        }
        .frame(height: 280)
    }

    // MARK: - Summary View

    private var summaryView: some View {
        let dataPoints = filteredDataPoints

        return VStack(spacing: 16) {
            if !dataPoints.isEmpty {
                // Period totals
                periodTotalsCard(for: dataPoints)

                // Average card
                averageCard(for: dataPoints)
            }
        }
    }

    private func periodTotalsCard(for dataPoints: [MonthlyDataPoint]) -> some View {
        let totalIncome = dataPoints.reduce(Decimal(0)) { $0 + $1.income }
        let totalExpenses = dataPoints.reduce(Decimal(0)) { $0 + $1.expenses }
        let totalNetIncome = dataPoints.reduce(Decimal(0)) { $0 + $1.netIncome }

        return VStack(spacing: 12) {
            HStack {
                Text("Period Totals")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 16) {
                // Total income
                VStack(alignment: .leading, spacing: 4) {
                    Text("Income")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatCurrency(totalIncome))
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }

                Spacer()

                // Total expenses
                VStack(spacing: 4) {
                    Text("Expenses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatCurrency(totalExpenses))
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                }

                Spacer()

                // Net income
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Net")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatCurrency(totalNetIncome))
                        .font(.subheadline.bold())
                        .foregroundStyle(totalNetIncome >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func averageCard(for dataPoints: [MonthlyDataPoint]) -> some View {
        let count = Decimal(dataPoints.count)
        guard count > 0 else { return AnyView(EmptyView()) }

        let avgIncome = dataPoints.reduce(Decimal(0)) { $0 + $1.income } / count
        let avgExpenses = dataPoints.reduce(Decimal(0)) { $0 + $1.expenses } / count
        let avgNetIncome = dataPoints.reduce(Decimal(0)) { $0 + $1.netIncome } / count

        return AnyView(
            VStack(spacing: 12) {
                HStack {
                    Text("Monthly Averages")
                        .font(.headline)
                    Spacer()
                    Text("\(dataPoints.count) month\(dataPoints.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    // Avg income
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Income")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(avgIncome))
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)
                    }

                    Spacer()

                    // Avg expenses
                    VStack(spacing: 4) {
                        Text("Expenses")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(avgExpenses))
                            .font(.subheadline.bold())
                            .foregroundStyle(.red)
                    }

                    Spacer()

                    // Avg net income
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Net")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatCurrency(avgNetIncome))
                            .font(.subheadline.bold())
                            .foregroundStyle(avgNetIncome >= 0 ? .green : .red)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        )
    }

    // MARK: - Computed Properties

    private var filteredDataPoints: [MonthlyDataPoint] {
        let calendar = Calendar.current
        let startDate: Date
        let endDate: Date

        if selectedTimeframe == .custom {
            startDate = calendar.startOfDay(for: customStartDate)
            endDate = calendar.startOfDay(for: customEndDate)
        } else {
            endDate = Date()
            startDate = selectedTimeframe.startDate(from: endDate)
        }

        let startComponents = calendar.dateComponents([.year, .month], from: startDate)
        let endComponents = calendar.dateComponents([.year, .month], from: endDate)

        return snapshots
            .filter { snapshot in
                let snapshotKey = snapshot.year * 100 + snapshot.month
                let startKey = (startComponents.year ?? 0) * 100 + (startComponents.month ?? 0)
                let endKey = (endComponents.year ?? 0) * 100 + (endComponents.month ?? 0)
                return snapshotKey >= startKey && snapshotKey <= endKey
            }
            .sorted { ($0.year * 100 + $0.month) < ($1.year * 100 + $1.month) }
            .map { snapshot in
                MonthlyDataPoint(
                    date: snapshot.date,
                    monthLabel: formatMonthLabel(year: snapshot.year, month: snapshot.month),
                    income: snapshot.totalIncomeValue,
                    expenses: snapshot.totalExpensesValue,
                    netIncome: snapshot.netIncomeValue
                )
            }
    }

    private var barChartEntries: [BarChartEntry] {
        var entries: [BarChartEntry] = []

        for point in filteredDataPoints {
            entries.append(BarChartEntry(
                monthLabel: point.monthLabel,
                category: "Income",
                value: NSDecimalNumber(decimal: point.income).doubleValue
            ))
            entries.append(BarChartEntry(
                monthLabel: point.monthLabel,
                category: "Expenses",
                value: NSDecimalNumber(decimal: point.expenses).doubleValue
            ))
        }

        return entries
    }

    // MARK: - Formatting Helpers

    private func formatMonthLabel(year: Int, month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"

        guard let date = Calendar.current.date(from: DateComponents(year: year, month: month)) else {
            return "\(month)"
        }

        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        if year == currentYear {
            return dateFormatter.string(from: date)
        } else {
            return "\(dateFormatter.string(from: date)) '\(String(year).suffix(2))"
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        CurrencyFormatter.format(value)
    }

    private func formatCurrencyCompact(_ value: Decimal) -> String {
        CurrencyFormatter.formatCompact(value)
    }
}

// MARK: - Preview

#Preview("With Data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MonthlySnapshot.self, configurations: config)

    // Generate sample monthly data for the past 12 months
    let calendar = Calendar.current
    let today = Date()

    for monthOffset in stride(from: -11, through: 0, by: 1) {
        if let date = calendar.date(byAdding: .month, value: monthOffset, to: today) {
            let components = calendar.dateComponents([.year, .month], from: date)

            // Generate random but realistic income/expense data
            let income = Decimal(Double.random(in: 4500...6500))
            let expenses = Decimal(Double.random(in: 2500...5000))

            let snapshot = MonthlySnapshot(
                year: components.year!,
                month: components.month!,
                income: income,
                expenses: expenses
            )
            container.mainContext.insert(snapshot)
        }
    }

    return NavigationStack {
        IncomeExpenseChartView()
    }
    .modelContainer(container)
}

#Preview("Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MonthlySnapshot.self, configurations: config)

    return NavigationStack {
        IncomeExpenseChartView()
    }
    .modelContainer(container)
}

#Preview("Net Income View") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MonthlySnapshot.self, configurations: config)

    // Generate data with some negative net income months
    let calendar = Calendar.current
    let today = Date()

    for monthOffset in stride(from: -5, through: 0, by: 1) {
        if let date = calendar.date(byAdding: .month, value: monthOffset, to: today) {
            let components = calendar.dateComponents([.year, .month], from: date)

            let income = Decimal(Double.random(in: 4000...6000))
            let expenses = Decimal(Double.random(in: 3500...6500)) // Sometimes exceeds income

            let snapshot = MonthlySnapshot(
                year: components.year!,
                month: components.month!,
                income: income,
                expenses: expenses
            )
            container.mainContext.insert(snapshot)
        }
    }

    return NavigationStack {
        IncomeExpenseChartView()
    }
    .modelContainer(container)
}
