//
//  TransactionFilterTests.swift
//  GhostVaultTests
//
//  Unit tests for TransactionFilter utility
//

import XCTest
@testable import GhostVault

final class TransactionFilterTests: XCTestCase {

    // MARK: - Test Data

    private var transactions: [Transaction]!

    override func setUp() {
        super.setUp()
        let today = Date()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: today)!

        transactions = [
            // Today - Income
            Transaction(
                id: "t1", accountId: "acc1", posted: today, amount: "2500.00",
                transactionDescription: "PAYROLL DEPOSIT ACME", payee: "ACME Inc",
                category: "Income", classificationReason: "Payee Rule"
            ),
            // Today - Expense
            Transaction(
                id: "t2", accountId: "acc1", posted: today, amount: "-45.99",
                transactionDescription: "AMAZON MARKETPLACE", payee: "Amazon",
                category: "Shopping", classificationReason: "Default"
            ),
            // Yesterday - Expense
            Transaction(
                id: "t3", accountId: "acc2", posted: yesterday, amount: "-12.50",
                transactionDescription: "STARBUCKS #12345", payee: "Starbucks",
                category: "Dining", classificationReason: "Default"
            ),
            // Yesterday - Transfer
            Transaction(
                id: "t4", accountId: "acc1", posted: yesterday, amount: "-500.00",
                transactionDescription: "TRANSFER TO SAVINGS", payee: "Transfer",
                category: "Transfer", classificationReason: "Auto-Transfer"
            ),
            // Last Month - Expense
            Transaction(
                id: "t5", accountId: "acc1", posted: lastMonth, amount: "-199.99",
                transactionDescription: "APPLE.COM/BILL", payee: "Apple",
                category: "Subscriptions", classificationReason: "Default"
            ),
            // Last Month - Ignored
            Transaction(
                id: "t6", accountId: "acc2", posted: lastMonth, amount: "-25.00",
                transactionDescription: "VENMO PAYMENT", payee: "Venmo",
                classificationReason: "Manual", isIgnored: true
            )
        ]
    }

    override func tearDown() {
        transactions = nil
        super.tearDown()
    }

    // MARK: - Search Filter Tests

    func testSearchFilter_ByPayee() {
        let results = TransactionFilter.searchFilter(text: "Amazon", in: transactions)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, "t2")
    }

    func testSearchFilter_ByDescription() {
        let results = TransactionFilter.searchFilter(text: "STARBUCKS", in: transactions)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, "t3")
    }

    func testSearchFilter_ByAmount() {
        let results = TransactionFilter.searchFilter(text: "2500", in: transactions)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, "t1")
    }

    func testSearchFilter_ByCategory() {
        let results = TransactionFilter.searchFilter(text: "shopping", in: transactions)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, "t2")
    }

    func testSearchFilter_CaseInsensitive() {
        let results = TransactionFilter.searchFilter(text: "apple", in: transactions)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, "t5")
    }

    func testSearchFilter_EmptyText() {
        let results = TransactionFilter.searchFilter(text: "", in: transactions)
        XCTAssertEqual(results.count, transactions.count)
    }

    func testSearchFilter_NoMatch() {
        let results = TransactionFilter.searchFilter(text: "xyz123", in: transactions)
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Quick Filter Tests

    func testQuickFilter_All() {
        let results = TransactionFilter.applyQuickFilter(.all, to: transactions)
        XCTAssertEqual(results.count, transactions.count)
    }

    func testQuickFilter_IncomeOnly() {
        let results = TransactionFilter.applyQuickFilter(.incomeOnly, to: transactions)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, "t1")
    }

    func testQuickFilter_ExpensesOnly() {
        let results = TransactionFilter.applyQuickFilter(.expensesOnly, to: transactions)
        // t2, t3, t5 are expenses (t4 is transfer, t6 is ignored)
        XCTAssertEqual(results.count, 3)
    }

    func testQuickFilter_ThisMonth() {
        let results = TransactionFilter.applyQuickFilter(.thisMonth, to: transactions)
        // t1, t2, t3, t4 are this month (today/yesterday)
        XCTAssertEqual(results.count, 4)
    }

    func testQuickFilter_LastMonth() {
        let results = TransactionFilter.applyQuickFilter(.lastMonth, to: transactions)
        // t5, t6 are last month
        XCTAssertEqual(results.count, 2)
    }

    // MARK: - Account Filter Tests

    func testFilterByAccount() {
        let results = TransactionFilter.filterByAccount("acc1", in: transactions)
        XCTAssertEqual(results.count, 4)
        XCTAssertTrue(results.allSatisfy { $0.accountId == "acc1" })
    }

    func testFilterByMultipleAccounts() {
        let results = TransactionFilter.filterByMultipleAccounts(["acc1", "acc2"], in: transactions)
        XCTAssertEqual(results.count, 6)
    }

    func testFilterByMultipleAccounts_EmptySet() {
        let results = TransactionFilter.filterByMultipleAccounts([], in: transactions)
        XCTAssertEqual(results.count, transactions.count)
    }

    // MARK: - Classification Filter Tests

    func testFilterByClassification_Income() {
        let results = TransactionFilter.filterByClassification(.income, in: transactions)
        XCTAssertEqual(results.count, 1)
    }

    func testFilterByClassification_Transfer() {
        let results = TransactionFilter.filterByClassification(.transfer, in: transactions)
        XCTAssertEqual(results.count, 1)
    }

    func testFilterByClassification_Ignored() {
        let results = TransactionFilter.filterByClassification(.ignored, in: transactions)
        XCTAssertEqual(results.count, 1)
    }

    func testFilterByMultipleClassifications() {
        let results = TransactionFilter.filterByMultipleClassifications([.income, .expense], in: transactions)
        XCTAssertEqual(results.count, 4)
    }

    // MARK: - Date Range Tests

    func testDateRange_ThisMonth() {
        let range = TransactionFilter.DateRange.thisMonth.dateRange()
        XCTAssertNotNil(range)
        XCTAssertTrue(range!.start <= Date())
        XCTAssertTrue(range!.end >= range!.start)
    }

    func testDateRange_LastMonth() {
        let range = TransactionFilter.DateRange.lastMonth.dateRange()
        XCTAssertNotNil(range)
        XCTAssertTrue(range!.end < Calendar.current.startOfDay(for: Date()))
    }

    func testDateRange_All() {
        let range = TransactionFilter.DateRange.all.dateRange()
        XCTAssertNil(range)
    }

    func testFilterByDateRange() {
        let calendar = Calendar.current
        let now = Date()
        // Use start of day to avoid timing issues
        let startOfYesterday = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: now)!)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        let results = TransactionFilter.filterByDateRange(start: startOfYesterday, end: endOfToday, in: transactions)
        XCTAssertEqual(results.count, 4)
    }

    // MARK: - Combined Options Tests

    func testApply_SearchAndQuickFilter() {
        var options = TransactionFilter.Options()
        options.searchText = "ACME"
        options.quickFilter = .incomeOnly

        let results = TransactionFilter.apply(options, to: transactions)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, "t1")
    }

    func testApply_AccountAndClassification() {
        var options = TransactionFilter.Options()
        options.accountIds = ["acc1"]
        options.classificationTypes = [.expense]

        let results = TransactionFilter.apply(options, to: transactions)
        XCTAssertEqual(results.count, 2) // t2, t5
    }

    func testApply_MultipleFilters() {
        var options = TransactionFilter.Options()
        options.searchText = "Star"
        options.accountIds = ["acc2"]

        let results = TransactionFilter.apply(options, to: transactions)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, "t3")
    }

    func testApply_NoFilters() {
        let options = TransactionFilter.Options()
        let results = TransactionFilter.apply(options, to: transactions)
        XCTAssertEqual(results.count, transactions.count)
    }

    // MARK: - Options Tests

    func testOptions_IsEmpty_Default() {
        let options = TransactionFilter.Options()
        XCTAssertTrue(options.isEmpty)
    }

    func testOptions_IsEmpty_WithSearchText() {
        var options = TransactionFilter.Options()
        options.searchText = "test"
        XCTAssertFalse(options.isEmpty)
    }

    func testOptions_IsEmpty_WithQuickFilter() {
        var options = TransactionFilter.Options()
        options.quickFilter = .incomeOnly
        XCTAssertFalse(options.isEmpty)
    }

    func testOptions_IsEmpty_WithAccountIds() {
        var options = TransactionFilter.Options()
        options.accountIds = ["acc1"]
        XCTAssertFalse(options.isEmpty)
    }

    func testOptions_IsEmpty_WithClassificationTypes() {
        var options = TransactionFilter.Options()
        options.classificationTypes = [.income]
        XCTAssertFalse(options.isEmpty)
    }

    func testOptions_IsEmpty_WithDateRange() {
        var options = TransactionFilter.Options()
        options.dateRange = .thisMonth
        XCTAssertFalse(options.isEmpty)
    }

    // MARK: - Date Range Equality Tests

    func testDateRange_Equality_All() {
        XCTAssertEqual(TransactionFilter.DateRange.all, TransactionFilter.DateRange.all)
    }

    func testDateRange_Equality_ThisMonth() {
        XCTAssertEqual(TransactionFilter.DateRange.thisMonth, TransactionFilter.DateRange.thisMonth)
    }

    func testDateRange_Equality_Custom() {
        let date1 = Date()
        let date2 = Calendar.current.date(byAdding: .day, value: 1, to: date1)!
        XCTAssertEqual(
            TransactionFilter.DateRange.custom(start: date1, end: date2),
            TransactionFilter.DateRange.custom(start: date1, end: date2)
        )
    }

    func testDateRange_Inequality() {
        XCTAssertNotEqual(TransactionFilter.DateRange.all, TransactionFilter.DateRange.thisMonth)
    }
}
