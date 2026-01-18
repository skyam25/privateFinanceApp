//
//  MonthlyIncomeCalculatorTests.swift
//  GhostVaultTests
//
//  Unit tests for monthly income calculation logic
//

import XCTest
@testable import GhostVault

final class MonthlyIncomeCalculatorTests: XCTestCase {

    // MARK: - Basic Calculations

    func testNetIncomeWithNoTransactions() {
        let result = MonthlyIncomeCalculator.calculate(transactions: [], for: Date())

        XCTAssertEqual(result.netIncome, 0)
        XCTAssertEqual(result.totalIncome, 0)
        XCTAssertEqual(result.totalExpenses, 0)
    }

    func testNetIncomeWithOnlyIncome() {
        let transactions = [
            makeTransaction(amount: "1000.00", category: "Income"),
            makeTransaction(amount: "500.00", category: "Income")
        ]

        let result = MonthlyIncomeCalculator.calculate(transactions: transactions, for: Date())

        XCTAssertEqual(result.totalIncome, 1500)
        XCTAssertEqual(result.totalExpenses, 0)
        XCTAssertEqual(result.netIncome, 1500)
    }

    func testNetIncomeWithOnlyExpenses() {
        let transactions = [
            makeTransaction(amount: "-50.00", category: "Dining"),
            makeTransaction(amount: "-100.00", category: "Groceries")
        ]

        let result = MonthlyIncomeCalculator.calculate(transactions: transactions, for: Date())

        XCTAssertEqual(result.totalIncome, 0)
        XCTAssertEqual(result.totalExpenses, 150)
        XCTAssertEqual(result.netIncome, -150)
    }

    func testNetIncomeWithMixedTransactions() {
        let transactions = [
            makeTransaction(amount: "3000.00", category: "Income"),
            makeTransaction(amount: "-500.00", category: "Groceries"),
            makeTransaction(amount: "-200.00", category: "Dining"),
            makeTransaction(amount: "-100.00", category: "Shopping")
        ]

        let result = MonthlyIncomeCalculator.calculate(transactions: transactions, for: Date())

        XCTAssertEqual(result.totalIncome, 3000)
        XCTAssertEqual(result.totalExpenses, 800)
        XCTAssertEqual(result.netIncome, 2200)
    }

    // MARK: - Transfer Exclusion

    func testTransfersAreExcluded() {
        let transactions = [
            makeTransaction(amount: "3000.00", category: "Income"),
            makeTransaction(amount: "-500.00", category: "Transfer"),
            makeTransaction(amount: "500.00", category: "Transfer"),
            makeTransaction(amount: "-100.00", category: "Groceries")
        ]

        let result = MonthlyIncomeCalculator.calculate(transactions: transactions, for: Date())

        XCTAssertEqual(result.totalIncome, 3000)
        XCTAssertEqual(result.totalExpenses, 100)
        XCTAssertEqual(result.netIncome, 2900)
    }

    func testTransfersAreCaseInsensitive() {
        let transactions = [
            makeTransaction(amount: "-500.00", category: "TRANSFER"),
            makeTransaction(amount: "500.00", category: "transfer")
        ]

        let result = MonthlyIncomeCalculator.calculate(transactions: transactions, for: Date())

        XCTAssertEqual(result.totalIncome, 0)
        XCTAssertEqual(result.totalExpenses, 0)
    }

    // MARK: - Month Filtering

    func testOnlyCurrentMonthTransactionsIncluded() {
        let calendar = Calendar.current
        let currentDate = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: currentDate)!

        let transactions = [
            makeTransaction(amount: "1000.00", category: "Income", date: currentDate),
            makeTransaction(amount: "500.00", category: "Income", date: lastMonth)
        ]

        let result = MonthlyIncomeCalculator.calculate(transactions: transactions, for: currentDate)

        XCTAssertEqual(result.totalIncome, 1000)
    }

    func testTransactionsFromDifferentYearSameMonthExcluded() {
        let calendar = Calendar.current
        let currentDate = Date()
        var lastYearComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
        lastYearComponents.year = (lastYearComponents.year ?? 0) - 1
        let lastYear = calendar.date(from: lastYearComponents)!

        let transactions = [
            makeTransaction(amount: "1000.00", category: "Income", date: currentDate),
            makeTransaction(amount: "500.00", category: "Income", date: lastYear)
        ]

        let result = MonthlyIncomeCalculator.calculate(transactions: transactions, for: currentDate)

        XCTAssertEqual(result.totalIncome, 1000)
    }

    // MARK: - Income Detection

    func testPositiveAmountWithIncomeCategory() {
        let transactions = [
            makeTransaction(amount: "1000.00", category: "Income")
        ]

        XCTAssertTrue(MonthlyIncomeCalculator.isIncome(transactions[0]))
    }

    func testPositiveAmountWithSalaryCategory() {
        let transactions = [
            makeTransaction(amount: "5000.00", category: "Salary")
        ]

        XCTAssertTrue(MonthlyIncomeCalculator.isIncome(transactions[0]))
    }

    func testPositiveAmountWithNonIncomeCategory() {
        // Refund treated as income (positive amount)
        let transaction = makeTransaction(amount: "50.00", category: "Shopping")

        XCTAssertTrue(MonthlyIncomeCalculator.isIncome(transaction))
    }

    func testNegativeAmountIsNotIncome() {
        let transaction = makeTransaction(amount: "-100.00", category: "Groceries")

        XCTAssertFalse(MonthlyIncomeCalculator.isIncome(transaction))
    }

    // MARK: - Edge Cases

    func testPendingTransactionsIncluded() {
        let transactions = [
            makeTransaction(amount: "1000.00", category: "Income", pending: true),
            makeTransaction(amount: "-50.00", category: "Dining", pending: true)
        ]

        let result = MonthlyIncomeCalculator.calculate(transactions: transactions, for: Date())

        XCTAssertEqual(result.totalIncome, 1000)
        XCTAssertEqual(result.totalExpenses, 50)
    }

    func testInvalidAmountTreatedAsZero() {
        let transactions = [
            makeTransaction(amount: "invalid", category: "Income")
        ]

        let result = MonthlyIncomeCalculator.calculate(transactions: transactions, for: Date())

        XCTAssertEqual(result.netIncome, 0)
    }

    func testNilCategoryTreatedAsExpense() {
        let transaction = makeTransaction(amount: "-75.00", category: nil)

        XCTAssertFalse(MonthlyIncomeCalculator.isIncome(transaction))
        XCTAssertFalse(MonthlyIncomeCalculator.isTransfer(transaction))
    }

    func testLargeAmounts() {
        let transactions = [
            makeTransaction(amount: "1234567.89", category: "Income")
        ]

        let result = MonthlyIncomeCalculator.calculate(transactions: transactions, for: Date())

        XCTAssertEqual(result.totalIncome, Decimal(string: "1234567.89"))
    }

    // MARK: - Month Info

    func testMonthInfoForCurrentDate() {
        let date = Date()
        let info = MonthlyIncomeCalculator.monthInfo(for: date)

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let expected = formatter.string(from: date)

        XCTAssertEqual(info.displayString, expected)
    }

    func testPreviousMonthCalculation() {
        let date = Date()
        let previousDate = MonthlyIncomeCalculator.previousMonth(from: date)

        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: date)
        let previousMonth = calendar.component(.month, from: previousDate)

        // Handle January -> December wrap
        if currentMonth == 1 {
            XCTAssertEqual(previousMonth, 12)
        } else {
            XCTAssertEqual(previousMonth, currentMonth - 1)
        }
    }

    func testNextMonthCalculation() {
        let date = Date()
        let nextDate = MonthlyIncomeCalculator.nextMonth(from: date)

        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: date)
        let nextMonth = calendar.component(.month, from: nextDate)

        // Handle December -> January wrap
        if currentMonth == 12 {
            XCTAssertEqual(nextMonth, 1)
        } else {
            XCTAssertEqual(nextMonth, currentMonth + 1)
        }
    }

    // MARK: - Helpers

    private func makeTransaction(
        amount: String,
        category: String?,
        date: Date = Date(),
        pending: Bool = false
    ) -> Transaction {
        Transaction(
            id: UUID().uuidString,
            accountId: "test-account",
            posted: date,
            amount: amount,
            transactionDescription: "Test Transaction",
            pending: pending,
            category: category
        )
    }
}
