//
//  CategoryTests.swift
//  GhostVaultTests
//
//  Unit tests for Category model and CategoryRule matching
//

import XCTest
import SwiftUI
@testable import GhostVault

final class CategoryTests: XCTestCase {

    // MARK: - CategoryRule Contains Match Tests

    func testContainsMatchInDescription() {
        let rule = CategoryRule(
            pattern: "amazon",
            field: .description,
            matchType: .contains
        )

        let transaction = Transaction(
            id: "txn-1",
            accountId: "acc-1",
            posted: Date(),
            amount: "-50.00",
            transactionDescription: "AMAZON.COM*123456"
        )

        XCTAssertTrue(rule.matches(transaction: transaction))
    }

    func testContainsMatchIsCaseInsensitive() {
        let rule = CategoryRule(
            pattern: "STARBUCKS",
            field: .description,
            matchType: .contains
        )

        let transaction = Transaction(
            id: "txn-2",
            accountId: "acc-1",
            posted: Date(),
            amount: "-5.50",
            transactionDescription: "starbucks coffee shop"
        )

        XCTAssertTrue(rule.matches(transaction: transaction))
    }

    func testContainsMatchFailsWhenNotPresent() {
        let rule = CategoryRule(
            pattern: "walmart",
            field: .description,
            matchType: .contains
        )

        let transaction = Transaction(
            id: "txn-3",
            accountId: "acc-1",
            posted: Date(),
            amount: "-50.00",
            transactionDescription: "TARGET STORE"
        )

        XCTAssertFalse(rule.matches(transaction: transaction))
    }

    // MARK: - CategoryRule StartsWith Match Tests

    func testStartsWithMatch() {
        let rule = CategoryRule(
            pattern: "payroll",
            field: .description,
            matchType: .startsWith
        )

        let transaction = Transaction(
            id: "txn-4",
            accountId: "acc-1",
            posted: Date(),
            amount: "3000.00",
            transactionDescription: "PAYROLL DIRECT DEPOSIT"
        )

        XCTAssertTrue(rule.matches(transaction: transaction))
    }

    func testStartsWithFailsWhenNotAtStart() {
        let rule = CategoryRule(
            pattern: "deposit",
            field: .description,
            matchType: .startsWith
        )

        let transaction = Transaction(
            id: "txn-5",
            accountId: "acc-1",
            posted: Date(),
            amount: "3000.00",
            transactionDescription: "PAYROLL DIRECT DEPOSIT"
        )

        XCTAssertFalse(rule.matches(transaction: transaction))
    }

    // MARK: - CategoryRule EndsWith Match Tests

    func testEndsWithMatch() {
        let rule = CategoryRule(
            pattern: "inc",
            field: .description,
            matchType: .endsWith
        )

        let transaction = Transaction(
            id: "txn-6",
            accountId: "acc-1",
            posted: Date(),
            amount: "3000.00",
            transactionDescription: "APPLE INC"
        )

        XCTAssertTrue(rule.matches(transaction: transaction))
    }

    func testEndsWithFailsWhenNotAtEnd() {
        let rule = CategoryRule(
            pattern: "apple",
            field: .description,
            matchType: .endsWith
        )

        let transaction = Transaction(
            id: "txn-7",
            accountId: "acc-1",
            posted: Date(),
            amount: "-10.00",
            transactionDescription: "APPLE INC"
        )

        XCTAssertFalse(rule.matches(transaction: transaction))
    }

    // MARK: - CategoryRule Regex Match Tests

    func testRegexMatchBasicPattern() {
        let rule = CategoryRule(
            pattern: "PAYROLL|SALARY|DIRECT DEP",
            field: .description,
            matchType: .regex
        )

        let transaction = Transaction(
            id: "txn-8",
            accountId: "acc-1",
            posted: Date(),
            amount: "3000.00",
            transactionDescription: "COMPANY SALARY PAYMENT"
        )

        XCTAssertTrue(rule.matches(transaction: transaction))
    }

    func testRegexMatchWithDigits() {
        let rule = CategoryRule(
            pattern: "AMZN\\*[A-Z0-9]+",
            field: .description,
            matchType: .regex
        )

        let transaction = Transaction(
            id: "txn-9",
            accountId: "acc-1",
            posted: Date(),
            amount: "-25.00",
            transactionDescription: "AMZN*MKTP US*AB12CD34"
        )

        XCTAssertTrue(rule.matches(transaction: transaction))
    }

    func testRegexMatchIsCaseInsensitive() {
        let rule = CategoryRule(
            pattern: "netflix",
            field: .description,
            matchType: .regex
        )

        let transaction = Transaction(
            id: "txn-10",
            accountId: "acc-1",
            posted: Date(),
            amount: "-15.99",
            transactionDescription: "NETFLIX.COM"
        )

        XCTAssertTrue(rule.matches(transaction: transaction))
    }

    func testInvalidRegexReturnsFalse() {
        let rule = CategoryRule(
            pattern: "[invalid(regex",
            field: .description,
            matchType: .regex
        )

        let transaction = Transaction(
            id: "txn-11",
            accountId: "acc-1",
            posted: Date(),
            amount: "-10.00",
            transactionDescription: "Test"
        )

        XCTAssertFalse(rule.matches(transaction: transaction))
    }

    // MARK: - CategoryRule Field Tests

    func testMatchInPayeeField() {
        let rule = CategoryRule(
            pattern: "starbucks",
            field: .payee,
            matchType: .contains
        )

        let transactionWithPayee = Transaction(
            id: "txn-12",
            accountId: "acc-1",
            posted: Date(),
            amount: "-6.50",
            transactionDescription: "CARD PURCHASE",
            payee: "Starbucks Coffee"
        )

        XCTAssertTrue(rule.matches(transaction: transactionWithPayee))
    }

    func testMatchInMemoField() {
        let rule = CategoryRule(
            pattern: "lunch",
            field: .memo,
            matchType: .contains
        )

        let transactionWithMemo = Transaction(
            id: "txn-13",
            accountId: "acc-1",
            posted: Date(),
            amount: "-15.00",
            transactionDescription: "RESTAURANT",
            memo: "Team lunch meeting"
        )

        XCTAssertTrue(rule.matches(transaction: transactionWithMemo))
    }

    func testMatchFailsWhenFieldIsNil() {
        let rule = CategoryRule(
            pattern: "test",
            field: .payee,
            matchType: .contains
        )

        let transactionNoPayee = Transaction(
            id: "txn-14",
            accountId: "acc-1",
            posted: Date(),
            amount: "-10.00",
            transactionDescription: "Test Transaction",
            payee: nil
        )

        XCTAssertFalse(rule.matches(transaction: transactionNoPayee))
    }

    // MARK: - Category Initialization Tests

    func testCategoryDefaultInitialization() {
        let category = Category(name: "Groceries")

        XCTAssertNotNil(category.id)
        XCTAssertEqual(category.name, "Groceries")
        XCTAssertEqual(category.iconName, "tag")
        XCTAssertEqual(category.colorHex, "#808080")
        XCTAssertTrue(category.rules.isEmpty)
    }

    func testCategoryFullInitialization() {
        let rule = CategoryRule(pattern: "whole foods", field: .description, matchType: .contains)
        let category = Category(
            name: "Groceries",
            iconName: "cart",
            colorHex: "#4CAF50",
            rules: [rule]
        )

        XCTAssertEqual(category.name, "Groceries")
        XCTAssertEqual(category.iconName, "cart")
        XCTAssertEqual(category.colorHex, "#4CAF50")
        XCTAssertEqual(category.rules.count, 1)
    }

    // MARK: - Color Extension Tests

    func testColorFromValidHex() {
        let color = Color(hex: "#FF5733")
        XCTAssertNotNil(color)
    }

    func testColorFromHexWithoutHash() {
        let color = Color(hex: "4CAF50")
        XCTAssertNotNil(color)
    }

    func testColorFromInvalidHexReturnsNil() {
        let color = Color(hex: "not-a-color")
        XCTAssertNil(color)
    }

    func testColorFromShortHexParsesAsLowDigits() {
        // Short hex like "FFF" is parsed as 0x000FFF, not 0xFFFFFF
        // This means it will be a valid color, but not white
        let color = Color(hex: "#FFF")
        XCTAssertNotNil(color) // Does parse, just not as expected short form
    }

    // MARK: - CategoryRule Codable Tests

    func testCategoryRuleEncodesAndDecodes() throws {
        let originalRule = CategoryRule(
            pattern: "amazon",
            field: .description,
            matchType: .contains
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalRule)

        let decoder = JSONDecoder()
        let decodedRule = try decoder.decode(CategoryRule.self, from: data)

        XCTAssertEqual(decodedRule.pattern, originalRule.pattern)
        XCTAssertEqual(decodedRule.field, originalRule.field)
        XCTAssertEqual(decodedRule.matchType, originalRule.matchType)
    }

    func testCategoryRuleHashable() {
        let rule1 = CategoryRule(pattern: "amazon", field: .description, matchType: .contains)
        let rule2 = CategoryRule(pattern: "amazon", field: .description, matchType: .contains)
        let rule3 = CategoryRule(pattern: "walmart", field: .description, matchType: .contains)

        XCTAssertEqual(rule1, rule2)
        XCTAssertNotEqual(rule1, rule3)

        var ruleSet = Set<CategoryRule>()
        ruleSet.insert(rule1)
        ruleSet.insert(rule2)
        XCTAssertEqual(ruleSet.count, 1)
    }
}
