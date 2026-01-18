//
//  NetWorthChartView.swift
//  GhostVault
//
//  Net worth trend line chart with timeframe selection
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Timeframe Enum

enum ChartTimeframe: String, CaseIterable, Identifiable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case yearToDate = "YTD"
    case oneYear = "1Y"
    case custom = "Custom"

    var id: String { rawValue }

    var displayName: String { rawValue }

    func startDate(from endDate: Date = Date()) -> Date {
        let calendar = Calendar.current
        switch self {
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: endDate) ?? endDate
        case .yearToDate:
            return calendar.date(from: calendar.dateComponents([.year], from: endDate)) ?? endDate
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        case .custom:
            return calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        }
    }
}

// MARK: - Chart Data Point

struct NetWorthDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let netWorth: Decimal
    let assets: Decimal
    let liabilities: Decimal
}

// MARK: - Net Worth Chart View

struct NetWorthChartView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var snapshots: [DailySnapshot]

    @State private var selectedTimeframe: ChartTimeframe = .oneMonth
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()
    @State private var showCustomDatePicker = false
    @State private var selectedDataPoint: NetWorthDataPoint?

    var body: some View {
        VStack(spacing: 0) {
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

                // Summary statistics
                summaryStats
                    .padding()
            }

            Spacer()
        }
        .navigationTitle("Net Worth Trend")
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

    // MARK: - Timeframe Selector

    private var timeframeSelector: some View {
        TimeframeSelectorView(
            selectedTimeframe: $selectedTimeframe,
            showCustomDatePicker: $showCustomDatePicker
        )
    }

    // MARK: - Chart View

    private var chartView: some View {
        let dataPoints = filteredDataPoints
        let yRange = calculateYRange(for: dataPoints)

        return Chart(dataPoints) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Net Worth", NSDecimalNumber(decimal: point.netWorth).doubleValue)
            )
            .foregroundStyle(chartGradient)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Date", point.date),
                y: .value("Net Worth", NSDecimalNumber(decimal: point.netWorth).doubleValue)
            )
            .foregroundStyle(areaGradient)
            .interpolationMethod(.catmullRom)

            if let selected = selectedDataPoint, selected.id == point.id {
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Net Worth", NSDecimalNumber(decimal: point.netWorth).doubleValue)
                )
                .foregroundStyle(Color.accentColor)
                .symbolSize(100)
            }
        }
        .chartYScale(domain: yRange)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisValueLabel(format: xAxisDateFormat)
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
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                selectDataPoint(at: value.location, proxy: proxy, geometry: geometry)
                            }
                            .onEnded { _ in
                                selectedDataPoint = nil
                            }
                    )
            }
        }
        .frame(height: 280)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Data", systemImage: "chart.line.uptrend.xyaxis")
        } description: {
            Text("Net worth snapshots will appear here after syncing your accounts.")
        }
        .frame(height: 280)
    }

    // MARK: - Summary Statistics

    private var summaryStats: some View {
        let dataPoints = filteredDataPoints

        return VStack(spacing: 16) {
            // Selected point details
            if let selected = selectedDataPoint {
                selectedPointCard(for: selected)
            }

            // Period summary
            if let first = dataPoints.first, let last = dataPoints.last {
                periodSummaryCard(from: first, to: last)
            }
        }
    }

    private func selectedPointCard(for point: NetWorthDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(point.date, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(formatCurrency(point.netWorth))
                .font(.title2.bold())

            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("Assets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatCurrency(point.assets))
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading) {
                    Text("Liabilities")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatCurrency(point.liabilities))
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func periodSummaryCard(from first: NetWorthDataPoint, to last: NetWorthDataPoint) -> some View {
        let change = last.netWorth - first.netWorth
        let percentChange = first.netWorth != 0
            ? (change / first.netWorth) * 100
            : Decimal(0)
        let isPositive = change >= 0

        return HStack(spacing: 16) {
            // Start value
            VStack(alignment: .leading, spacing: 4) {
                Text("Start")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatCurrencyCompact(first.netWorth))
                    .font(.subheadline.bold())
            }

            Spacer()

            // Change indicator
            VStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isPositive ? .green : .red)

                HStack(spacing: 2) {
                    Text(isPositive ? "+" : "")
                    Text(formatCurrencyCompact(abs(change)))
                }
                .font(.caption.bold())
                .foregroundStyle(isPositive ? .green : .red)

                Text("(\(formatPercentage(abs(percentChange))))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // End value
            VStack(alignment: .trailing, spacing: 4) {
                Text("End")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatCurrencyCompact(last.netWorth))
                    .font(.subheadline.bold())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Computed Properties

    private var filteredDataPoints: [NetWorthDataPoint] {
        let startDate: Date
        let endDate: Date

        if selectedTimeframe == .custom {
            startDate = Calendar.current.startOfDay(for: customStartDate)
            endDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: customEndDate) ?? customEndDate)
        } else {
            endDate = Date()
            startDate = selectedTimeframe.startDate(from: endDate)
        }

        return snapshots
            .filter { $0.date >= startDate && $0.date <= endDate }
            .sorted { $0.date < $1.date }
            .map { snapshot in
                NetWorthDataPoint(
                    date: snapshot.date,
                    netWorth: snapshot.netWorthValue,
                    assets: snapshot.totalAssetsValue,
                    liabilities: abs(snapshot.totalLiabilitiesValue)
                )
            }
    }

    private var chartGradient: LinearGradient {
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.1)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var xAxisDateFormat: Date.FormatStyle {
        switch selectedTimeframe {
        case .oneMonth:
            return .dateTime.day()
        case .threeMonths, .yearToDate:
            return .dateTime.month(.abbreviated).day()
        case .oneYear, .custom:
            return .dateTime.month(.abbreviated)
        }
    }

    // MARK: - Helper Functions

    private func calculateYRange(for dataPoints: [NetWorthDataPoint]) -> ClosedRange<Double> {
        guard !dataPoints.isEmpty else { return 0...100 }

        let values = dataPoints.map { NSDecimalNumber(decimal: $0.netWorth).doubleValue }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 100

        // Add 10% padding
        let padding = (maxValue - minValue) * 0.1
        return (minValue - padding)...(maxValue + padding)
    }

    private func selectDataPoint(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard !filteredDataPoints.isEmpty else { return }

        let xPosition = location.x - geometry[proxy.plotFrame!].origin.x

        guard let date: Date = proxy.value(atX: xPosition) else { return }

        // Find closest data point
        let closest = filteredDataPoints.min { a, b in
            abs(a.date.timeIntervalSince(date)) < abs(b.date.timeIntervalSince(date))
        }

        selectedDataPoint = closest
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }

    private func formatCurrencyCompact(_ value: Decimal) -> String {
        let doubleValue = NSDecimalNumber(decimal: abs(value)).doubleValue
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"

        let prefix = value < 0 ? "-" : ""

        if doubleValue >= 1_000_000 {
            formatter.maximumFractionDigits = 1
            return "\(prefix)\(formatter.string(from: NSNumber(value: doubleValue / 1_000_000)) ?? "$0")M"
        } else if doubleValue >= 1_000 {
            formatter.maximumFractionDigits = 0
            return "\(prefix)\(formatter.string(from: NSNumber(value: doubleValue / 1_000)) ?? "$0")K"
        } else {
            formatter.maximumFractionDigits = 0
            return formatter.string(from: value as NSDecimalNumber) ?? "$0"
        }
    }

    private func formatPercentage(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        formatter.multiplier = 0.01
        return formatter.string(from: value as NSDecimalNumber) ?? "0%"
    }
}

// MARK: - Preview

#Preview("With Data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DailySnapshot.self, Account.self, configurations: config)

    // Generate sample data for the past 3 months
    let calendar = Calendar.current
    let today = Date()
    var baseNetWorth: Decimal = 150000

    for dayOffset in stride(from: -90, through: 0, by: 1) {
        if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
            // Add some variation
            let dailyChange = Decimal(Double.random(in: -500...800))
            baseNetWorth += dailyChange

            let assets = baseNetWorth + 50000
            let liabilities = Decimal(-50000)

            let snapshot = DailySnapshot(
                date: date,
                netWorth: "\(baseNetWorth)",
                totalAssets: "\(assets)",
                totalLiabilities: "\(liabilities)"
            )
            container.mainContext.insert(snapshot)
        }
    }

    return NavigationStack {
        NetWorthChartView()
    }
    .modelContainer(container)
}

#Preview("Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DailySnapshot.self, Account.self, configurations: config)

    return NavigationStack {
        NetWorthChartView()
    }
    .modelContainer(container)
}

#Preview("1 Month View") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DailySnapshot.self, Account.self, configurations: config)

    // Generate sample data for the past month
    let calendar = Calendar.current
    let today = Date()
    var baseNetWorth: Decimal = 100000

    for dayOffset in stride(from: -30, through: 0, by: 1) {
        if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
            let dailyChange = Decimal(Double.random(in: -300...500))
            baseNetWorth += dailyChange

            let assets = baseNetWorth + 30000
            let liabilities = Decimal(-30000)

            let snapshot = DailySnapshot(
                date: date,
                netWorth: "\(baseNetWorth)",
                totalAssets: "\(assets)",
                totalLiabilities: "\(liabilities)"
            )
            container.mainContext.insert(snapshot)
        }
    }

    return NavigationStack {
        NetWorthChartView()
    }
    .modelContainer(container)
}
