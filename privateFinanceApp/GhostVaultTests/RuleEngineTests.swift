//
//  RuleEngineTests.swift
//  GhostVaultTests
//
//  Unit tests for RuleEngine and ClassificationRule
//

import XCTest
@testable import GhostVault

final class RuleEngineTests: XCTestCase {

    private let today = Date()

    // MARK: - Classification Rule Tests

    func testClassificationRule_Matches_PayeeContains() {
        let rule = ClassificationRule(payee: "Amazon", category: "Shopping")
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "PURCHASE", payee: "Amazon Marketplace"
        )

        XCTAssertTrue(rule.matches(transaction))
    }

    func testClassificationRule_Matches_DescriptionContains() {
        let rule = ClassificationRule(payee: "Starbucks", category: "Dining")
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-5.00",
            transactionDescription: "STARBUCKS #12345"
        )

        XCTAssertTrue(rule.matches(transaction))
    }

    func testClassificationRule_Matches_CaseInsensitive() {
        let rule = ClassificationRule(payee: "amazon", category: "Shopping")
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "AMAZON MARKETPLACE"
        )

        XCTAssertTrue(rule.matches(transaction))
    }

    func testClassificationRule_Matches_NoMatch() {
        let rule = ClassificationRule(payee: "Netflix", category: "Subscriptions")
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "AMAZON", payee: "Amazon"
        )

        XCTAssertFalse(rule.matches(transaction))
    }

    func testClassificationRule_Matches_Inactive() {
        let rule = ClassificationRule(payee: "Amazon", category: "Shopping", isActive: false)
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "AMAZON"
        )

        XCTAssertFalse(rule.matches(transaction))
    }

    func testClassificationRule_Apply() {
        let rule = ClassificationRule(payee: "Starbucks", category: "Dining")
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-5.00",
            transactionDescription: "STARBUCKS"
        )

        rule.apply(to: transaction)

        XCTAssertEqual(transaction.category, "Dining")
        XCTAssertEqual(transaction.classificationReason, "Payee Rule: Starbucks")
    }

    // MARK: - Classification Priority Tests

    func testPriority_Default() {
        XCTAssertEqual(ClassificationPriority.from(reason: nil), .default)
        XCTAssertEqual(ClassificationPriority.from(reason: "Default"), .default)
    }

    func testPriority_PatternIncome() {
        XCTAssertEqual(ClassificationPriority.from(reason: "Pattern: Payroll"), .patternIncome)
        XCTAssertEqual(ClassificationPriority.from(reason: "Pattern: Direct Deposit"), .patternIncome)
    }

    func testPriority_AutoTransfer() {
        XCTAssertEqual(ClassificationPriority.from(reason: "Auto-Transfer"), .autoTransfer)
    }

    func testPriority_AutoCCPayment() {
        XCTAssertEqual(ClassificationPriority.from(reason: "Auto-CC Payment"), .autoCCPayment)
        XCTAssertEqual(ClassificationPriority.from(reason: "CC Payment Detected"), .autoCCPayment)
    }

    func testPriority_Manual() {
        XCTAssertEqual(ClassificationPriority.from(reason: "Manual"), .manual)
    }

    func testPriority_PayeeRule() {
        XCTAssertEqual(ClassificationPriority.from(reason: "Payee Rule: Amazon"), .payeeRule)
    }

    func testPriority_Ordering() {
        XCTAssertTrue(ClassificationPriority.default < ClassificationPriority.patternIncome)
        XCTAssertTrue(ClassificationPriority.patternIncome < ClassificationPriority.autoTransfer)
        XCTAssertTrue(ClassificationPriority.autoTransfer < ClassificationPriority.autoCCPayment)
        XCTAssertTrue(ClassificationPriority.autoCCPayment < ClassificationPriority.manual)
        XCTAssertTrue(ClassificationPriority.manual < ClassificationPriority.payeeRule)
    }

    // MARK: - Rule Engine Tests

    func testApplyBestRule_Matches() {
        let rules = [
            ClassificationRule(payee: "Amazon", category: "Shopping")
        ]
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "AMAZON MARKETPLACE"
        )

        let result = RuleEngine.applyBestRule(to: transaction, rules: rules)

        XCTAssertTrue(result)
        XCTAssertEqual(transaction.category, "Shopping")
    }

    func testApplyBestRule_NoMatch() {
        let rules = [
            ClassificationRule(payee: "Netflix", category: "Subscriptions")
        ]
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "AMAZON"
        )

        let result = RuleEngine.applyBestRule(to: transaction, rules: rules)

        XCTAssertFalse(result)
        XCTAssertNil(transaction.category)
    }

    func testApplyBestRule_RespectsExistingPriority() {
        let rules = [
            ClassificationRule(payee: "Amazon", category: "Shopping")
        ]
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "AMAZON", classificationReason: "Manual"
        )
        transaction.category = "Gifts"

        // Manual has lower priority than Payee Rule, so it should override
        let result = RuleEngine.applyBestRule(to: transaction, rules: rules)

        XCTAssertTrue(result)
        XCTAssertEqual(transaction.category, "Shopping")
    }

    func testApplyBestRule_Force() {
        let rules = [
            ClassificationRule(payee: "Amazon", category: "Shopping")
        ]
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "AMAZON", classificationReason: "Payee Rule: Old"
        )
        transaction.category = "Old Category"

        let result = RuleEngine.applyBestRule(to: transaction, rules: rules, force: true)

        XCTAssertTrue(result)
        XCTAssertEqual(transaction.category, "Shopping")
    }

    // MARK: - CC Payment Detection Tests

    func testCCPaymentDetection_Matches() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-500.00",
            transactionDescription: "CREDIT CARD PAYMENT"
        )

        let result = RuleEngine.applyCCPaymentDetection(to: transaction)

        XCTAssertTrue(result)
        XCTAssertEqual(transaction.category, "Transfer")
        XCTAssertEqual(transaction.classificationReason, "Auto-CC Payment")
    }

    func testCCPaymentDetection_PositiveAmount() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "500.00",
            transactionDescription: "CREDIT CARD PAYMENT"
        )

        let result = RuleEngine.applyCCPaymentDetection(to: transaction)

        XCTAssertFalse(result) // Only negative amounts are payments
    }

    func testCCPaymentDetection_NoMatch() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "AMAZON PURCHASE"
        )

        let result = RuleEngine.applyCCPaymentDetection(to: transaction)

        XCTAssertFalse(result)
    }

    // MARK: - Default Classification Tests

    func testDefaultClassification_Positive() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "100.00",
            transactionDescription: "DEPOSIT"
        )

        RuleEngine.applyDefaultClassification(to: transaction)

        XCTAssertEqual(transaction.category, "Income")
        XCTAssertEqual(transaction.classificationReason, "Default")
    }

    func testDefaultClassification_Negative() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "PURCHASE"
        )

        RuleEngine.applyDefaultClassification(to: transaction)

        XCTAssertEqual(transaction.category, "Expense")
        XCTAssertEqual(transaction.classificationReason, "Default")
    }

    // MARK: - Full Classification Tests

    func testClassify_PayeeRuleHighestPriority() {
        let rules = [
            ClassificationRule(payee: "PAYROLL", category: "Work Income")
        ]
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "2500.00",
            transactionDescription: "PAYROLL DEPOSIT", payee: "PAYROLL SERVICES"
        )

        let priority = RuleEngine.classify(transaction: transaction, rules: rules)

        XCTAssertEqual(priority, .payeeRule)
        XCTAssertEqual(transaction.category, "Work Income")
    }

    func testClassify_ManualNotOverridden() {
        let rules = [
            ClassificationRule(payee: "Amazon", category: "Shopping")
        ]
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "AMAZON", classificationReason: "Manual"
        )
        transaction.category = "Gifts"

        // But payee rule has higher priority than manual
        let priority = RuleEngine.classify(transaction: transaction, rules: rules)

        XCTAssertEqual(priority, .payeeRule)
    }

    func testClassify_PatternIncome() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "2500.00",
            transactionDescription: "PAYROLL DEPOSIT ACME INC"
        )

        let priority = RuleEngine.classify(transaction: transaction, rules: [])

        XCTAssertEqual(priority, .patternIncome)
        XCTAssertEqual(transaction.category, "Income")
    }

    func testClassify_Default() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "UNKNOWN MERCHANT"
        )

        let priority = RuleEngine.classify(transaction: transaction, rules: [])

        XCTAssertEqual(priority, .default)
        XCTAssertEqual(transaction.category, "Expense")
    }

    // MARK: - Rule Creation Tests

    func testCreateRule_FromPayee() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "AMAZON MARKETPLACE", payee: "Amazon"
        )

        let rule = RuleEngine.createRule(from: transaction, category: "Shopping")

        XCTAssertNotNil(rule)
        XCTAssertEqual(rule?.payee, "Amazon")
        XCTAssertEqual(rule?.category, "Shopping")
    }

    func testCreateRule_FallbackToDescription() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "STARBUCKS #12345"
        )

        let rule = RuleEngine.createRule(from: transaction, category: "Dining")

        XCTAssertNotNil(rule)
        XCTAssertEqual(rule?.payee, "STARBUCKS")
        XCTAssertEqual(rule?.category, "Dining")
    }

    func testCreateRule_ShortDescription() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-5.00",
            transactionDescription: "AB"
        )

        let rule = RuleEngine.createRule(from: transaction, category: "Other")

        XCTAssertNil(rule) // Description word too short
    }

    // MARK: - Priority Checking Tests

    func testCanOverride_HigherPriority() {
        XCTAssertTrue(RuleEngine.canOverride(newReason: "Payee Rule: Test", existingReason: "Default"))
        XCTAssertTrue(RuleEngine.canOverride(newReason: "Manual", existingReason: "Pattern: Payroll"))
    }

    func testCanOverride_LowerPriority() {
        XCTAssertFalse(RuleEngine.canOverride(newReason: "Default", existingReason: "Manual"))
        XCTAssertFalse(RuleEngine.canOverride(newReason: "Pattern: Payroll", existingReason: "Payee Rule: Test"))
    }

    func testCanOverride_SamePriority() {
        XCTAssertFalse(RuleEngine.canOverride(newReason: "Pattern: A", existingReason: "Pattern: B"))
    }

    // MARK: - Statistics Tests

    func testCountByReason() {
        let transactions = [
            Transaction(id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
                       transactionDescription: "A", classificationReason: "Default"),
            Transaction(id: "t2", accountId: "acc1", posted: today, amount: "-50.00",
                       transactionDescription: "B", classificationReason: "Default"),
            Transaction(id: "t3", accountId: "acc1", posted: today, amount: "100.00",
                       transactionDescription: "C", classificationReason: "Pattern: Payroll"),
            Transaction(id: "t4", accountId: "acc1", posted: today, amount: "-50.00",
                       transactionDescription: "D", classificationReason: "Payee Rule: Test")
        ]

        let counts = RuleEngine.countByReason(transactions)

        XCTAssertEqual(counts["Default"], 2)
        XCTAssertEqual(counts["Pattern: Payroll"], 1)
        XCTAssertEqual(counts["Payee Rule: Test"], 1)
    }

    func testCountMatches() {
        let rule = ClassificationRule(payee: "Amazon", category: "Shopping")
        let transactions = [
            Transaction(id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
                       transactionDescription: "AMAZON MARKETPLACE"),
            Transaction(id: "t2", accountId: "acc1", posted: today, amount: "-25.00",
                       transactionDescription: "AMAZON PRIME"),
            Transaction(id: "t3", accountId: "acc1", posted: today, amount: "-100.00",
                       transactionDescription: "WALMART")
        ]

        let count = RuleEngine.countMatches(for: rule, in: transactions)

        XCTAssertEqual(count, 2)
    }

    // MARK: - Priority Property Test

    func testPriority_OfTransaction() {
        let transaction = Transaction(
            id: "t1", accountId: "acc1", posted: today, amount: "-50.00",
            transactionDescription: "TEST", classificationReason: "Payee Rule: Test"
        )

        XCTAssertEqual(RuleEngine.priority(of: transaction), .payeeRule)
    }
}
