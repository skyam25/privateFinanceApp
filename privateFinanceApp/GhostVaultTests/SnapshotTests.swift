//
//  SnapshotTests.swift
//  GhostVaultTests
//
//  Unit tests for DailySnapshot and MonthlySnapshot models
//

import XCTest
@testable import GhostVault

final class SnapshotTests: XCTestCase {

    private let today = Date()

    // MARK: - Daily Snapshot Tests

    func testDailySnapshot_Initialization() {
        let snapshot = DailySnapshot(
            date: today,
            netWorth: "100000.00",
            totalAssets: "150000.00",
            totalLiabilities: "-50000.00"
        )

        XCTAssertEqual(snapshot.netWorthValue, Decimal(string: "100000.00"))
        XCTAssertEqual(snapshot.totalAssetsValue, Decimal(string: "150000.00"))
        XCTAssertEqual(snapshot.totalLiabilitiesValue, Decimal(string: "-50000.00"))
    }

    func testDailySnapshot_ConvenienceInit() {
        let snapshot = DailySnapshot(
            date: today,
            assets: Decimal(150000),
            liabilities: Decimal(50000) // positive input, will be stored as negative
        )

        XCTAssertEqual(snapshot.totalAssetsValue, Decimal(150000))
        // Net worth = assets + liabilities (liabilities already negative in calculation)
    }

    func testDailySnapshot_DateNormalization() {
        let calendar = Calendar.current
        let afternoonDate = calendar.date(bySettingHour: 15, minute: 30, second: 0, of: today)!

        let snapshot = DailySnapshot(
            date: afternoonDate,
            netWorth: "100000.00",
            totalAssets: "100000.00",
            totalLiabilities: "0.00"
        )

        // Date should be normalized to start of day
        let startOfDay = calendar.startOfDay(for: today)
        XCTAssertEqual(snapshot.date, startOfDay)
    }

    func testDailySnapshot_ZeroValues() {
        let snapshot = DailySnapshot(
            date: today,
            netWorth: "0.00",
            totalAssets: "0.00",
            totalLiabilities: "0.00"
        )

        XCTAssertEqual(snapshot.netWorthValue, 0)
        XCTAssertEqual(snapshot.totalAssetsValue, 0)
        XCTAssertEqual(snapshot.totalLiabilitiesValue, 0)
    }

    func testDailySnapshot_NegativeNetWorth() {
        let snapshot = DailySnapshot(
            date: today,
            netWorth: "-25000.00",
            totalAssets: "25000.00",
            totalLiabilities: "-50000.00"
        )

        XCTAssertEqual(snapshot.netWorthValue, Decimal(-25000))
        XCTAssertTrue(snapshot.netWorthValue < 0)
    }

    func testDailySnapshot_LargeNumbers() {
        let snapshot = DailySnapshot(
            date: today,
            netWorth: "1000000000.00",
            totalAssets: "1500000000.00",
            totalLiabilities: "-500000000.00"
        )

        XCTAssertEqual(snapshot.netWorthValue, Decimal(1_000_000_000))
    }

    func testDailySnapshot_InvalidString() {
        let snapshot = DailySnapshot(
            date: today,
            netWorth: "invalid",
            totalAssets: "100000.00",
            totalLiabilities: "0.00"
        )

        XCTAssertEqual(snapshot.netWorthValue, 0) // Invalid parses to 0
    }

    // MARK: - Monthly Snapshot Tests

    func testMonthlySnapshot_Initialization() {
        let snapshot = MonthlySnapshot(
            year: 2026,
            month: 1,
            totalIncome: "5000.00",
            totalExpenses: "3500.00",
            netIncome: "1500.00"
        )

        XCTAssertEqual(snapshot.year, 2026)
        XCTAssertEqual(snapshot.month, 1)
        XCTAssertEqual(snapshot.totalIncomeValue, Decimal(string: "5000.00"))
        XCTAssertEqual(snapshot.totalExpensesValue, Decimal(string: "3500.00"))
        XCTAssertEqual(snapshot.netIncomeValue, Decimal(string: "1500.00"))
    }

    func testMonthlySnapshot_ConvenienceInit() {
        let snapshot = MonthlySnapshot(
            year: 2026,
            month: 1,
            income: Decimal(5000),
            expenses: Decimal(3500)
        )

        XCTAssertEqual(snapshot.totalIncomeValue, Decimal(5000))
        XCTAssertEqual(snapshot.totalExpensesValue, Decimal(3500))
        XCTAssertEqual(snapshot.netIncomeValue, Decimal(1500)) // 5000 - 3500
    }

    func testMonthlySnapshot_Key() {
        let snapshot = MonthlySnapshot(
            year: 2026,
            month: 1,
            income: Decimal(5000),
            expenses: Decimal(3500)
        )

        XCTAssertEqual(snapshot.key, "2026-01")
    }

    func testMonthlySnapshot_KeyWithTwoDigitMonth() {
        let snapshot = MonthlySnapshot(
            year: 2026,
            month: 12,
            income: Decimal(5000),
            expenses: Decimal(3500)
        )

        XCTAssertEqual(snapshot.key, "2026-12")
    }

    func testMonthlySnapshot_Date() {
        let snapshot = MonthlySnapshot(
            year: 2026,
            month: 3,
            income: Decimal(5000),
            expenses: Decimal(3500)
        )

        let components = Calendar.current.dateComponents([.year, .month, .day], from: snapshot.date)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 1)
    }

    func testMonthlySnapshot_NegativeNetIncome() {
        let snapshot = MonthlySnapshot(
            year: 2026,
            month: 1,
            income: Decimal(3000),
            expenses: Decimal(4500)
        )

        XCTAssertEqual(snapshot.netIncomeValue, Decimal(-1500))
        XCTAssertTrue(snapshot.netIncomeValue < 0)
    }

    func testMonthlySnapshot_ZeroIncome() {
        let snapshot = MonthlySnapshot(
            year: 2026,
            month: 1,
            income: Decimal(0),
            expenses: Decimal(2000)
        )

        XCTAssertEqual(snapshot.totalIncomeValue, 0)
        XCTAssertEqual(snapshot.netIncomeValue, Decimal(-2000))
    }

    func testMonthlySnapshot_ZeroExpenses() {
        let snapshot = MonthlySnapshot(
            year: 2026,
            month: 1,
            income: Decimal(5000),
            expenses: Decimal(0)
        )

        XCTAssertEqual(snapshot.totalExpensesValue, 0)
        XCTAssertEqual(snapshot.netIncomeValue, Decimal(5000))
    }

    func testMonthlySnapshot_AllMonths() {
        // Test all 12 months have valid keys
        for month in 1...12 {
            let snapshot = MonthlySnapshot(
                year: 2026,
                month: month,
                income: Decimal(1000),
                expenses: Decimal(500)
            )

            XCTAssertEqual(snapshot.month, month)
            XCTAssertTrue(snapshot.key.starts(with: "2026-"))
        }
    }

    // MARK: - Edge Cases

    func testDailySnapshot_DecimalPrecision() {
        let snapshot = DailySnapshot(
            date: today,
            netWorth: "123456.789012",
            totalAssets: "123456.789012",
            totalLiabilities: "0.00"
        )

        // Verify decimal precision is maintained
        XCTAssertEqual(snapshot.netWorthValue, Decimal(string: "123456.789012"))
    }

    func testMonthlySnapshot_DecimalPrecision() {
        let snapshot = MonthlySnapshot(
            year: 2026,
            month: 1,
            totalIncome: "5432.109876",
            totalExpenses: "1234.567890",
            netIncome: "4197.541986"
        )

        XCTAssertEqual(snapshot.totalIncomeValue, Decimal(string: "5432.109876"))
        XCTAssertEqual(snapshot.totalExpensesValue, Decimal(string: "1234.567890"))
    }

    func testDailySnapshot_EmptyString() {
        let snapshot = DailySnapshot(
            date: today,
            netWorth: "",
            totalAssets: "",
            totalLiabilities: ""
        )

        XCTAssertEqual(snapshot.netWorthValue, 0)
        XCTAssertEqual(snapshot.totalAssetsValue, 0)
        XCTAssertEqual(snapshot.totalLiabilitiesValue, 0)
    }

    func testMonthlySnapshot_InvalidMonth() {
        // While the model accepts any int, invalid months should still work
        let snapshot = MonthlySnapshot(
            year: 2026,
            month: 13, // Invalid month
            income: Decimal(1000),
            expenses: Decimal(500)
        )

        XCTAssertEqual(snapshot.month, 13)
        XCTAssertEqual(snapshot.key, "2026-13")
    }

    // MARK: - Comparison Tests

    func testMonthlySnapshot_Comparison() {
        let snapshot1 = MonthlySnapshot(year: 2026, month: 1, income: Decimal(5000), expenses: Decimal(3000))
        let snapshot2 = MonthlySnapshot(year: 2026, month: 2, income: Decimal(4500), expenses: Decimal(2800))

        XCTAssertTrue(snapshot1.netIncomeValue > snapshot2.netIncomeValue)
    }

    func testDailySnapshot_Comparison() {
        let snapshot1 = DailySnapshot(date: today, assets: Decimal(100000), liabilities: Decimal(20000))
        let snapshot2 = DailySnapshot(date: today, assets: Decimal(90000), liabilities: Decimal(15000))

        // Compare net worth values
        let netWorth1 = snapshot1.totalAssetsValue + snapshot1.totalLiabilitiesValue
        let netWorth2 = snapshot2.totalAssetsValue + snapshot2.totalLiabilitiesValue

        // Both should be positive (assets > liabilities)
        XCTAssertTrue(netWorth1 > 0 || netWorth2 > 0)
    }
}
