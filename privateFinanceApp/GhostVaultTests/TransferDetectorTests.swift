//
//  TransferDetectorTests.swift
//  GhostVaultTests
//
//  Unit tests for TransferDetector utility
//

import XCTest
@testable import GhostVault

final class TransferDetectorTests: XCTestCase {

    // MARK: - Test Data

    private var transactions: [Transaction]!
    private let today = Date()

    override func setUp() {
        super.setUp()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        transactions = [
            // Matching transfer pair (checking -> savings)
            Transaction(
                id: "t1", accountId: "checking", posted: today, amount: "-500.00",
                transactionDescription: "TRANSFER TO SAVINGS", payee: "Internal Transfer"
            ),
            Transaction(
                id: "t2", accountId: "savings", posted: today, amount: "500.00",
                transactionDescription: "TRANSFER FROM CHECKING", payee: "Internal Transfer"
            ),
            // Regular expense (not a transfer)
            Transaction(
                id: "t3", accountId: "checking", posted: yesterday, amount: "-50.00",
                transactionDescription: "AMAZON MARKETPLACE", payee: "Amazon"
            ),
            // Regular income (not a transfer)
            Transaction(
                id: "t4", accountId: "checking", posted: twoDaysAgo, amount: "2500.00",
                transactionDescription: "PAYROLL DEPOSIT", payee: "Employer Inc"
            )
        ]
    }

    override func tearDown() {
        transactions = nil
        super.tearDown()
    }

    // MARK: - Basic Detection Tests

    func testDetectTransfers_MatchingPair() {
        let matches = TransferDetector.detectTransfers(in: transactions)
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.outgoing.id, "t1")
        XCTAssertEqual(matches.first?.incoming.id, "t2")
    }

    func testDetectTransfers_NoMatches() {
        // Only regular transactions, no transfers
        let nonTransfers = [transactions[2], transactions[3]]
        let matches = TransferDetector.detectTransfers(in: nonTransfers)
        XCTAssertEqual(matches.count, 0)
    }

    func testDetectTransfers_EmptyArray() {
        let matches = TransferDetector.detectTransfers(in: [])
        XCTAssertEqual(matches.count, 0)
    }

    // MARK: - Amount Matching Tests

    func testDetectTransfers_AmountsMustMatch() {
        let mismatchedAmount = Transaction(
            id: "t5", accountId: "savings", posted: today, amount: "499.99",
            transactionDescription: "TRANSFER FROM CHECKING"
        )
        let testTransactions = [transactions[0], mismatchedAmount]
        let matches = TransferDetector.detectTransfers(in: testTransactions)
        XCTAssertEqual(matches.count, 0)
    }

    func testDetectTransfers_AbsoluteValueComparison() {
        // Outgoing is negative, incoming is positive - amounts match in absolute value
        XCTAssertEqual(abs(transactions[0].amountValue), transactions[1].amountValue)
    }

    // MARK: - Account Tests

    func testDetectTransfers_DifferentAccountsRequired() {
        let sameAccountTransfer = Transaction(
            id: "t5", accountId: "checking", posted: today, amount: "500.00",
            transactionDescription: "TRANSFER FROM CHECKING"
        )
        let testTransactions = [transactions[0], sameAccountTransfer]
        let matches = TransferDetector.detectTransfers(in: testTransactions)
        XCTAssertEqual(matches.count, 0)
    }

    // MARK: - Date Range Tests

    func testIsWithinDateRange_SameDay() {
        let date1 = today
        let date2 = today
        XCTAssertTrue(TransferDetector.isWithinDateRange(date1, date2))
    }

    func testIsWithinDateRange_OneDayApart() {
        let date1 = today
        let date2 = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        XCTAssertTrue(TransferDetector.isWithinDateRange(date1, date2))
    }

    func testIsWithinDateRange_ThreeDaysApart() {
        let date1 = today
        let date2 = Calendar.current.date(byAdding: .day, value: 3, to: today)!
        XCTAssertTrue(TransferDetector.isWithinDateRange(date1, date2))
    }

    func testIsWithinDateRange_FourDaysApart() {
        let date1 = today
        let date2 = Calendar.current.date(byAdding: .day, value: 4, to: today)!
        XCTAssertFalse(TransferDetector.isWithinDateRange(date1, date2))
    }

    func testDetectTransfers_OutsideDateRange() {
        let calendar = Calendar.current
        let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: today)!

        let outOfRange = Transaction(
            id: "t5", accountId: "savings", posted: fourDaysAgo, amount: "500.00",
            transactionDescription: "TRANSFER FROM CHECKING"
        )
        let testTransactions = [transactions[0], outOfRange]
        let matches = TransferDetector.detectTransfers(in: testTransactions)
        XCTAssertEqual(matches.count, 0)
    }

    // MARK: - Pending Transactions Tests

    func testDetectTransfers_ExcludesPendingTransactions() {
        let pendingTransfer = Transaction(
            id: "t5", accountId: "checking", posted: today, amount: "-200.00",
            transactionDescription: "TRANSFER TO SAVINGS", pending: true
        )
        let matchingIncoming = Transaction(
            id: "t6", accountId: "savings", posted: today, amount: "200.00",
            transactionDescription: "TRANSFER FROM CHECKING"
        )
        let testTransactions = [pendingTransfer, matchingIncoming]
        let matches = TransferDetector.detectTransfers(in: testTransactions)
        XCTAssertEqual(matches.count, 0)
    }

    func testDetectTransfers_ExcludesPendingIncoming() {
        let outgoing = Transaction(
            id: "t5", accountId: "checking", posted: today, amount: "-200.00",
            transactionDescription: "TRANSFER TO SAVINGS"
        )
        let pendingIncoming = Transaction(
            id: "t6", accountId: "savings", posted: today, amount: "200.00",
            transactionDescription: "TRANSFER FROM CHECKING", pending: true
        )
        let testTransactions = [outgoing, pendingIncoming]
        let matches = TransferDetector.detectTransfers(in: testTransactions)
        XCTAssertEqual(matches.count, 0)
    }

    // MARK: - Already Matched Tests

    func testDetectTransfers_ExcludesAlreadyMatched() {
        transactions[0].matchedTransferId = "t2"
        transactions[1].matchedTransferId = "t1"

        let matches = TransferDetector.detectTransfers(in: transactions)
        XCTAssertEqual(matches.count, 0)
    }

    // MARK: - Apply Matches Tests

    func testApplyMatches_LinksTransactions() {
        let matches = TransferDetector.detectTransfers(in: transactions)
        TransferDetector.applyMatches(matches)

        XCTAssertEqual(transactions[0].matchedTransferId, "t2")
        XCTAssertEqual(transactions[1].matchedTransferId, "t1")
    }

    func testApplyMatches_SetsCategory() {
        let matches = TransferDetector.detectTransfers(in: transactions)
        TransferDetector.applyMatches(matches)

        XCTAssertEqual(transactions[0].category, "Transfer")
        XCTAssertEqual(transactions[1].category, "Transfer")
    }

    func testApplyMatches_SetsClassificationReason() {
        let matches = TransferDetector.detectTransfers(in: transactions)
        TransferDetector.applyMatches(matches)

        XCTAssertEqual(transactions[0].classificationReason, "Auto-Transfer")
        XCTAssertEqual(transactions[1].classificationReason, "Auto-Transfer")
    }

    // MARK: - Process Transfers Tests

    func testProcessTransfers_ReturnsMatchCount() {
        let count = TransferDetector.processTransfers(transactions)
        XCTAssertEqual(count, 1)
    }

    func testProcessTransfers_UpdatesTransactions() {
        TransferDetector.processTransfers(transactions)
        XCTAssertNotNil(transactions[0].matchedTransferId)
        XCTAssertNotNil(transactions[1].matchedTransferId)
    }

    // MARK: - Looks Like Transfer Tests

    func testLooksLikeTransfer_TransferKeyword() {
        let transfer = Transaction(
            id: "t1", accountId: "checking", posted: today, amount: "-100.00",
            transactionDescription: "TRANSFER TO SAVINGS"
        )
        XCTAssertTrue(TransferDetector.looksLikeTransfer(transfer))
    }

    func testLooksLikeTransfer_XferKeyword() {
        let transfer = Transaction(
            id: "t1", accountId: "checking", posted: today, amount: "-100.00",
            transactionDescription: "XFER TO SAVINGS"
        )
        XCTAssertTrue(TransferDetector.looksLikeTransfer(transfer))
    }

    func testLooksLikeTransfer_InPayee() {
        let transfer = Transaction(
            id: "t1", accountId: "checking", posted: today, amount: "-100.00",
            transactionDescription: "SOME DESC", payee: "Internal Transfer"
        )
        XCTAssertTrue(TransferDetector.looksLikeTransfer(transfer))
    }

    func testLooksLikeTransfer_NotATransfer() {
        let regular = Transaction(
            id: "t1", accountId: "checking", posted: today, amount: "-50.00",
            transactionDescription: "AMAZON MARKETPLACE", payee: "Amazon"
        )
        XCTAssertFalse(TransferDetector.looksLikeTransfer(regular))
    }

    // MARK: - Unmatch Transfer Tests

    func testUnmatchTransfer_ClearsMatchIds() {
        TransferDetector.processTransfers(transactions)
        TransferDetector.unmatchTransfer(transaction1: transactions[0], transaction2: transactions[1])

        XCTAssertNil(transactions[0].matchedTransferId)
        XCTAssertNil(transactions[1].matchedTransferId)
    }

    func testUnmatchTransfer_ResetsClassification() {
        TransferDetector.processTransfers(transactions)
        TransferDetector.unmatchTransfer(transaction1: transactions[0], transaction2: transactions[1])

        XCTAssertNil(transactions[0].category)
        XCTAssertEqual(transactions[0].classificationReason, "Default")
    }

    // MARK: - Statistics Tests

    func testCountUnmatchedTransfers() {
        // Before matching, t1 and t2 look like transfers
        let count = TransferDetector.countUnmatchedTransfers(in: transactions)
        XCTAssertEqual(count, 2)
    }

    func testCountUnmatchedTransfers_AfterMatching() {
        TransferDetector.processTransfers(transactions)
        let count = TransferDetector.countUnmatchedTransfers(in: transactions)
        XCTAssertEqual(count, 0)
    }

    func testMatchedTransferIds() {
        TransferDetector.processTransfers(transactions)
        let ids = TransferDetector.matchedTransferIds(in: transactions)

        XCTAssertEqual(ids.count, 2)
        XCTAssertTrue(ids.contains("t1"))
        XCTAssertTrue(ids.contains("t2"))
    }

    // MARK: - Multiple Transfers Tests

    func testDetectTransfers_MultipleMatches() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Add another transfer pair
        let secondOutgoing = Transaction(
            id: "t5", accountId: "checking", posted: yesterday, amount: "-1000.00",
            transactionDescription: "TRANSFER TO SAVINGS"
        )
        let secondIncoming = Transaction(
            id: "t6", accountId: "savings", posted: yesterday, amount: "1000.00",
            transactionDescription: "TRANSFER FROM CHECKING"
        )
        transactions.append(contentsOf: [secondOutgoing, secondIncoming])

        let matches = TransferDetector.detectTransfers(in: transactions)
        XCTAssertEqual(matches.count, 2)
    }

    // MARK: - isMatchedTransfer Property Tests

    func testIsMatchedTransfer_WhenMatched() {
        TransferDetector.processTransfers(transactions)
        XCTAssertTrue(transactions[0].isMatchedTransfer)
        XCTAssertTrue(transactions[1].isMatchedTransfer)
    }

    func testIsMatchedTransfer_WhenNotMatched() {
        XCTAssertFalse(transactions[2].isMatchedTransfer)
        XCTAssertFalse(transactions[3].isMatchedTransfer)
    }
}
