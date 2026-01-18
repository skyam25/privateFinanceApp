//
//  TransactionTests.swift
//  GhostVaultTests
//
//  Unit tests for Transaction model
//

import XCTest
@testable import GhostVault

final class TransactionTests: XCTestCase {

    // MARK: - Amount Parsing Tests

    func testAmountValueParsesPositiveDecimal() {
        let transaction = Transaction(
            id: "txn-1",
            accountId: "acc-1",
            posted: Date(),
            amount: "125.50",
            transactionDescription: "Direct Deposit"
        )
        XCTAssertEqual(transaction.amountValue, Decimal(string: "125.50"))
    }

    func testAmountValueParsesNegativeDecimal() {
        let transaction = Transaction(
            id: "txn-2",
            accountId: "acc-1",
            posted: Date(),
            amount: "-45.99",
            transactionDescription: "Amazon Purchase"
        )
        XCTAssertEqual(transaction.amountValue, Decimal(string: "-45.99"))
    }

    func testAmountValueReturnsZeroForInvalidString() {
        let transaction = Transaction(
            id: "txn-3",
            accountId: "acc-1",
            posted: Date(),
            amount: "invalid",
            transactionDescription: "Bad Data"
        )
        XCTAssertEqual(transaction.amountValue, Decimal(0))
    }

    func testAmountValueHandlesSmallDecimals() {
        let transaction = Transaction(
            id: "txn-4",
            accountId: "acc-1",
            posted: Date(),
            amount: "0.01",
            transactionDescription: "Penny Transaction"
        )
        XCTAssertEqual(transaction.amountValue, Decimal(string: "0.01"))
    }

    // MARK: - Category Icon Tests

    func testCategoryIconForDining() {
        let transaction = Transaction(
            id: "txn-5",
            accountId: "acc-1",
            posted: Date(),
            amount: "-25.00",
            transactionDescription: "Restaurant",
            category: "Food & Dining"
        )
        XCTAssertEqual(transaction.categoryIcon, "fork.knife")
    }

    func testCategoryIconForShopping() {
        let transaction = Transaction(
            id: "txn-6",
            accountId: "acc-1",
            posted: Date(),
            amount: "-100.00",
            transactionDescription: "Target",
            category: "Shopping"
        )
        XCTAssertEqual(transaction.categoryIcon, "bag")
    }

    func testCategoryIconForGroceries() {
        let transaction = Transaction(
            id: "txn-7",
            accountId: "acc-1",
            posted: Date(),
            amount: "-75.00",
            transactionDescription: "Whole Foods",
            category: "Groceries"
        )
        XCTAssertEqual(transaction.categoryIcon, "cart")
    }

    func testCategoryIconForTransportation() {
        let transaction = Transaction(
            id: "txn-8",
            accountId: "acc-1",
            posted: Date(),
            amount: "-50.00",
            transactionDescription: "Shell Gas",
            category: "Transportation"
        )
        XCTAssertEqual(transaction.categoryIcon, "car")
    }

    func testCategoryIconForBills() {
        let transaction = Transaction(
            id: "txn-9",
            accountId: "acc-1",
            posted: Date(),
            amount: "-120.00",
            transactionDescription: "Electric Bill",
            category: "Bills & Utilities"
        )
        XCTAssertEqual(transaction.categoryIcon, "bolt")
    }

    func testCategoryIconForEntertainment() {
        let transaction = Transaction(
            id: "txn-10",
            accountId: "acc-1",
            posted: Date(),
            amount: "-15.99",
            transactionDescription: "Netflix",
            category: "Entertainment"
        )
        XCTAssertEqual(transaction.categoryIcon, "tv")
    }

    func testCategoryIconForHealth() {
        let transaction = Transaction(
            id: "txn-11",
            accountId: "acc-1",
            posted: Date(),
            amount: "-50.00",
            transactionDescription: "Gym Membership",
            category: "Health & Fitness"
        )
        XCTAssertEqual(transaction.categoryIcon, "heart")
    }

    func testCategoryIconForTravel() {
        let transaction = Transaction(
            id: "txn-12",
            accountId: "acc-1",
            posted: Date(),
            amount: "-500.00",
            transactionDescription: "United Airlines",
            category: "Travel"
        )
        XCTAssertEqual(transaction.categoryIcon, "airplane")
    }

    func testCategoryIconForIncome() {
        let transaction = Transaction(
            id: "txn-13",
            accountId: "acc-1",
            posted: Date(),
            amount: "3000.00",
            transactionDescription: "Payroll",
            category: "Income"
        )
        XCTAssertEqual(transaction.categoryIcon, "arrow.down.circle")
    }

    func testCategoryIconForTransfer() {
        let transaction = Transaction(
            id: "txn-14",
            accountId: "acc-1",
            posted: Date(),
            amount: "-200.00",
            transactionDescription: "Transfer to Savings",
            category: "Transfer"
        )
        XCTAssertEqual(transaction.categoryIcon, "arrow.left.arrow.right")
    }

    func testCategoryIconForSubscriptions() {
        let transaction = Transaction(
            id: "txn-15",
            accountId: "acc-1",
            posted: Date(),
            amount: "-9.99",
            transactionDescription: "Spotify",
            category: "Subscriptions"
        )
        XCTAssertEqual(transaction.categoryIcon, "repeat")
    }

    func testCategoryIconForNilCategory() {
        let transaction = Transaction(
            id: "txn-16",
            accountId: "acc-1",
            posted: Date(),
            amount: "-50.00",
            transactionDescription: "Unknown Purchase",
            category: nil
        )
        XCTAssertEqual(transaction.categoryIcon, "questionmark.circle")
    }

    func testCategoryIconForUnknownCategory() {
        let transaction = Transaction(
            id: "txn-17",
            accountId: "acc-1",
            posted: Date(),
            amount: "-50.00",
            transactionDescription: "Mystery",
            category: "Random Category"
        )
        XCTAssertEqual(transaction.categoryIcon, "questionmark.circle")
    }

    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        let postDate = Date()
        let transaction = Transaction(
            id: "txn-18",
            accountId: "acc-1",
            posted: postDate,
            amount: "100.00",
            transactionDescription: "Test Transaction"
        )

        XCTAssertEqual(transaction.id, "txn-18")
        XCTAssertEqual(transaction.accountId, "acc-1")
        XCTAssertEqual(transaction.posted, postDate)
        XCTAssertEqual(transaction.amount, "100.00")
        XCTAssertEqual(transaction.transactionDescription, "Test Transaction")
        XCTAssertNil(transaction.payee)
        XCTAssertNil(transaction.memo)
        XCTAssertFalse(transaction.pending)
        XCTAssertNil(transaction.category)
    }

    func testFullInitialization() {
        let postDate = Date()
        let transaction = Transaction(
            id: "txn-19",
            accountId: "acc-2",
            posted: postDate,
            amount: "-75.00",
            transactionDescription: "AMAZON.COM*123456",
            payee: "Amazon",
            memo: "Book purchase",
            pending: true,
            category: "Shopping"
        )

        XCTAssertEqual(transaction.payee, "Amazon")
        XCTAssertEqual(transaction.memo, "Book purchase")
        XCTAssertTrue(transaction.pending)
        XCTAssertEqual(transaction.category, "Shopping")
    }

    func testPendingTransactionFlag() {
        let pendingTxn = Transaction(
            id: "txn-20",
            accountId: "acc-1",
            posted: Date(),
            amount: "-50.00",
            transactionDescription: "Pending Purchase",
            pending: true
        )
        XCTAssertTrue(pendingTxn.pending)

        let clearedTxn = Transaction(
            id: "txn-21",
            accountId: "acc-1",
            posted: Date(),
            amount: "-50.00",
            transactionDescription: "Cleared Purchase",
            pending: false
        )
        XCTAssertFalse(clearedTxn.pending)
    }
}
