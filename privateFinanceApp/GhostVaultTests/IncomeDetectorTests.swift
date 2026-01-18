//
//  IncomeDetectorTests.swift
//  GhostVaultTests
//
//  Unit tests for IncomeDetector utility
//

import XCTest
@testable import GhostVault

final class IncomeDetectorTests: XCTestCase {

    private let today = Date()

    // MARK: - Pattern Matching Tests

    func testPatternMatches_Payroll() {
        XCTAssertTrue(IncomeDetector.patternMatches("payroll", in: "PAYROLL DEPOSIT"))
        XCTAssertTrue(IncomeDetector.patternMatches("payroll", in: "ACH PAYROLL DEPOSIT"))
        XCTAssertTrue(IncomeDetector.patternMatches("payroll", in: "payroll"))
    }

    func testPatternMatches_DirectDeposit() {
        XCTAssertTrue(IncomeDetector.patternMatches("direct\\s*dep(osit)?", in: "DIRECT DEPOSIT"))
        XCTAssertTrue(IncomeDetector.patternMatches("direct\\s*dep(osit)?", in: "DIRECTDEP"))
        XCTAssertTrue(IncomeDetector.patternMatches("direct\\s*dep(osit)?", in: "Direct Dep"))
    }

    func testPatternMatches_Salary() {
        XCTAssertTrue(IncomeDetector.patternMatches("salary", in: "SALARY PAYMENT"))
        XCTAssertTrue(IncomeDetector.patternMatches("salary", in: "Monthly Salary"))
    }

    func testPatternMatches_Wages() {
        XCTAssertTrue(IncomeDetector.patternMatches("wages?", in: "WAGE DEPOSIT"))
        XCTAssertTrue(IncomeDetector.patternMatches("wages?", in: "WAGES"))
    }

    func testPatternMatches_SocialSecurity() {
        XCTAssertTrue(IncomeDetector.patternMatches("ssa\\s*(treas|payment)", in: "SSA TREAS"))
        XCTAssertTrue(IncomeDetector.patternMatches("social\\s*security", in: "SOCIAL SECURITY"))
    }

    func testPatternMatches_TaxRefund() {
        XCTAssertTrue(IncomeDetector.patternMatches("irs\\s*(treas|refund)", in: "IRS TREAS"))
        XCTAssertTrue(IncomeDetector.patternMatches("tax\\s*refund", in: "TAX REFUND"))
    }

    func testPatternMatches_Dividend() {
        XCTAssertTrue(IncomeDetector.patternMatches("dividend", in: "DIVIDEND PAYMENT"))
        XCTAssertTrue(IncomeDetector.patternMatches("dividend", in: "Stock Dividend"))
    }

    func testPatternMatches_Interest() {
        XCTAssertTrue(IncomeDetector.patternMatches("interest\\s*(payment|credit)", in: "INTEREST PAYMENT"))
        XCTAssertTrue(IncomeDetector.patternMatches("interest\\s*(payment|credit)", in: "Interest Credit"))
    }

    func testPatternMatches_CaseInsensitive() {
        XCTAssertTrue(IncomeDetector.patternMatches("payroll", in: "payroll"))
        XCTAssertTrue(IncomeDetector.patternMatches("payroll", in: "PAYROLL"))
        XCTAssertTrue(IncomeDetector.patternMatches("payroll", in: "Payroll"))
        XCTAssertTrue(IncomeDetector.patternMatches("payroll", in: "PayRoll"))
    }

    func testPatternMatches_NoMatch() {
        XCTAssertFalse(IncomeDetector.patternMatches("payroll", in: "AMAZON PURCHASE"))
        XCTAssertFalse(IncomeDetector.patternMatches("payroll", in: "STARBUCKS"))
    }

    // MARK: - Income Pattern Matching Tests

    func testMatchesIncomePattern_Payroll() {
        let reason = IncomeDetector.matchesIncomePattern("PAYROLL DEPOSIT ACME INC")
        XCTAssertEqual(reason, "Payroll")
    }

    func testMatchesIncomePattern_DirectDeposit() {
        let reason = IncomeDetector.matchesIncomePattern("DIRECT DEPOSIT FROM EMPLOYER")
        XCTAssertEqual(reason, "Direct Deposit")
    }

    func testMatchesIncomePattern_Salary() {
        let reason = IncomeDetector.matchesIncomePattern("MONTHLY SALARY")
        XCTAssertEqual(reason, "Salary")
    }

    func testMatchesIncomePattern_NoMatch() {
        let reason = IncomeDetector.matchesIncomePattern("AMAZON MARKETPLACE")
        XCTAssertNil(reason)
    }

    func testMatchesIncomePattern_Refund() {
        let reason = IncomeDetector.matchesIncomePattern("RETURN REFUND")
        XCTAssertEqual(reason, "Refund")
    }

    func testMatchesIncomePattern_Reimbursement() {
        let reason = IncomeDetector.matchesIncomePattern("EXPENSE REIMBURSEMENT")
        XCTAssertEqual(reason, "Reimbursement")
    }

    // MARK: - Detect Income Tests

    func testDetectIncome_MatchingTransaction() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "2500.00",
            transactionDescription: "PAYROLL DEPOSIT ACME INC", payee: "ACME Inc"
        )

        let result = IncomeDetector.detectIncome(transaction)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.isIncome)
        XCTAssertEqual(result!.reason, "Payroll")
    }

    func testDetectIncome_NegativeAmount() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "PAYROLL DEPOSIT" // Even with payroll description
        )

        let result = IncomeDetector.detectIncome(transaction)
        XCTAssertNil(result) // Negative amounts are not income
    }

    func testDetectIncome_IgnoredTransaction() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "2500.00",
            transactionDescription: "PAYROLL DEPOSIT", isIgnored: true
        )

        let result = IncomeDetector.detectIncome(transaction)
        XCTAssertNil(result) // Ignored transactions skip detection
    }

    func testDetectIncome_TransferCategory() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "500.00",
            transactionDescription: "TRANSFER FROM CHECKING", category: "Transfer"
        )

        let result = IncomeDetector.detectIncome(transaction)
        XCTAssertNil(result) // Transfers skip income detection
    }

    func testDetectIncome_MatchInPayee() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "3000.00",
            transactionDescription: "ACH CREDIT", payee: "PAYROLL SERVICES INC"
        )

        let result = IncomeDetector.detectIncome(transaction)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.reason, "Payroll")
    }

    func testDetectIncome_MatchInMemo() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "2500.00",
            transactionDescription: "ACH CREDIT", memo: "SALARY PAYMENT FOR JAN"
        )

        let result = IncomeDetector.detectIncome(transaction)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.reason, "Salary")
    }

    func testDetectIncome_RegularExpense() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "25.00",
            transactionDescription: "AMAZON RETURN", payee: "Amazon"
        )

        // Note: This matches "refund" pattern even though it's from Amazon
        let result = IncomeDetector.detectIncome(transaction)
        // The word "return" doesn't match but if it said "refund" it would
        XCTAssertNil(result)
    }

    // MARK: - Apply Classification Tests

    func testApplyIncomeClassification() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "2500.00",
            transactionDescription: "PAYROLL DEPOSIT"
        )

        IncomeDetector.applyIncomeClassification(to: transaction, reason: "Payroll")

        XCTAssertEqual(transaction.category, "Income")
        XCTAssertEqual(transaction.classificationReason, "Pattern: Payroll")
    }

    // MARK: - Process Transaction Tests

    func testProcessTransaction_MatchingIncome() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "2500.00",
            transactionDescription: "PAYROLL DEPOSIT ACME INC"
        )

        let result = IncomeDetector.processTransaction(transaction)

        XCTAssertTrue(result)
        XCTAssertEqual(transaction.category, "Income")
        XCTAssertEqual(transaction.classificationReason, "Pattern: Payroll")
    }

    func testProcessTransaction_NonIncome() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "AMAZON MARKETPLACE"
        )

        let result = IncomeDetector.processTransaction(transaction)

        XCTAssertFalse(result)
        XCTAssertNil(transaction.category)
    }

    // MARK: - Process Multiple Transactions Tests

    func testProcessTransactions_MultipleMatches() {
        let transactions = [
            Transaction(
                id: "t1", accountId: "acc1", posted: today, amount: "2500.00",
                transactionDescription: "PAYROLL DEPOSIT"
            ),
            Transaction(
                id: "t2", accountId: "acc1", posted: today, amount: "-50.00",
                transactionDescription: "AMAZON"
            ),
            Transaction(
                id: "t3", accountId: "acc1", posted: today, amount: "100.00",
                transactionDescription: "REFUND FROM STORE"
            )
        ]

        let count = IncomeDetector.processTransactions(transactions)

        XCTAssertEqual(count, 2) // Payroll and Refund
    }

    // MARK: - Statistics Tests

    func testCountPotentialIncome() {
        let transactions = [
            Transaction(
                id: "t1", accountId: "acc1", posted: today, amount: "2500.00",
                transactionDescription: "UNKNOWN DEPOSIT"
            ),
            Transaction(
                id: "t2", accountId: "acc1", posted: today, amount: "-50.00",
                transactionDescription: "AMAZON"
            ),
            Transaction(
                id: "t3", accountId: "acc1", posted: today, amount: "100.00",
                transactionDescription: "TRANSFER FROM SAVINGS", category: "Transfer"
            ),
            Transaction(
                id: "t4", accountId: "acc1", posted: today, amount: "500.00",
                transactionDescription: "ALREADY CLASSIFIED", category: "Income"
            )
        ]

        let count = IncomeDetector.countPotentialIncome(in: transactions)
        XCTAssertEqual(count, 1) // Only t1 (unknown positive, not transfer/income)
    }

    // MARK: - All Patterns Tests

    func testAllPatternNames() {
        let names = IncomeDetector.allPatternNames
        XCTAssertTrue(names.contains("Payroll"))
        XCTAssertTrue(names.contains("Direct Deposit"))
        XCTAssertTrue(names.contains("Salary"))
        XCTAssertTrue(names.contains("Dividend"))
        XCTAssertTrue(names.contains("Refund"))
    }

    // MARK: - Edge Case Tests

    func testDetectIncome_ZeroAmount() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "0.00",
            transactionDescription: "PAYROLL ADJUSTMENT"
        )

        let result = IncomeDetector.detectIncome(transaction)
        XCTAssertNil(result) // Zero is not positive
    }

    func testDetectIncome_VerySmallAmount() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "0.01",
            transactionDescription: "DIVIDEND PAYMENT"
        )

        let result = IncomeDetector.detectIncome(transaction)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.reason, "Dividend")
    }

    func testDetectIncome_PartialPatternMatch() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "100.00",
            transactionDescription: "SOMETHING PAYROLL SOMETHING"
        )

        let result = IncomeDetector.detectIncome(transaction)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.reason, "Payroll")
    }

    // MARK: - Comprehensive Pattern Tests

    func testDetectIncome_ACHCredit() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "1500.00",
            transactionDescription: "ACH CREDIT FROM COMPANY"
        )

        let result = IncomeDetector.detectIncome(transaction)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.reason, "ACH Credit")
    }

    func testDetectIncome_WireTransfer() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "5000.00",
            transactionDescription: "WIRE TRANSFER IN FROM OVERSEAS"
        )

        let result = IncomeDetector.detectIncome(transaction)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.reason, "Wire Transfer")
    }

    func testDetectIncome_Bonus() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "5000.00",
            transactionDescription: "ANNUAL BONUS PAYMENT"
        )

        let result = IncomeDetector.detectIncome(transaction)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.reason, "Bonus")
    }

    func testDetectIncome_Cashback() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "50.00",
            transactionDescription: "CREDIT CARD CASHBACK"
        )

        let result = IncomeDetector.detectIncome(transaction)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.reason, "Cashback")
    }

    func testDetectIncome_Unemployment() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "450.00",
            transactionDescription: "STATE UNEMPLOYMENT PAYMENT"
        )

        let result = IncomeDetector.detectIncome(transaction)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.reason, "Unemployment")
    }
}
