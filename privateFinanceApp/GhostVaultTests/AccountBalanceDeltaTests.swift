//
//  AccountBalanceDeltaTests.swift
//  GhostVaultTests
//
//  Tests for AccountBalanceDelta utility
//

import XCTest
@testable import GhostVault

final class AccountBalanceDeltaTests: XCTestCase {

    // MARK: - Basic Delta Calculation

    func testCalculateDelta_PositiveChange() {
        let delta = AccountBalanceDelta.calculate(current: 1500, previous: 1000)

        XCTAssertNotNil(delta)
        XCTAssertEqual(delta?.amount, 500)
        XCTAssertTrue(delta?.isPositive ?? false)
        XCTAssertFalse(delta?.isZero ?? true)
    }

    func testCalculateDelta_NegativeChange() {
        let delta = AccountBalanceDelta.calculate(current: 800, previous: 1000)

        XCTAssertNotNil(delta)
        XCTAssertEqual(delta?.amount, -200)
        XCTAssertFalse(delta?.isPositive ?? true)
        XCTAssertFalse(delta?.isZero ?? true)
    }

    func testCalculateDelta_NoChange() {
        let delta = AccountBalanceDelta.calculate(current: 1000, previous: 1000)

        XCTAssertNotNil(delta)
        XCTAssertEqual(delta?.amount, 0)
        XCTAssertTrue(delta?.isPositive ?? false)
        XCTAssertTrue(delta?.isZero ?? false)
    }

    func testCalculateDelta_NilPrevious() {
        let delta = AccountBalanceDelta.calculate(current: 1000, previous: nil)

        XCTAssertNil(delta)
    }

    // MARK: - Percentage Calculation

    func testPercentageChange_50PercentIncrease() {
        let delta = AccountBalanceDelta.calculate(current: 1500, previous: 1000)

        XCTAssertNotNil(delta?.percentageChange)
        XCTAssertEqual(delta?.percentageChange, 50)
    }

    func testPercentageChange_25PercentDecrease() {
        let delta = AccountBalanceDelta.calculate(current: 750, previous: 1000)

        XCTAssertNotNil(delta?.percentageChange)
        XCTAssertEqual(delta?.percentageChange, -25)
    }

    func testPercentageChange_ZeroPreviousBalance() {
        let delta = AccountBalanceDelta.calculate(current: 1000, previous: 0)

        XCTAssertNotNil(delta)
        XCTAssertNil(delta?.percentageChange) // Avoid division by zero
    }

    func testPercentageChange_DoubleBalance() {
        let delta = AccountBalanceDelta.calculate(current: 2000, previous: 1000)

        XCTAssertEqual(delta?.percentageChange, 100)
    }

    // MARK: - Account-Based Calculation

    func testCalculateForAccount_WithPreviousBalance() {
        let account = Account(
            id: "test-1",
            name: "Test Account",
            balance: "1500.00",
            previousBalance: "1000.00"
        )

        let delta = AccountBalanceDelta.calculate(for: account)

        XCTAssertNotNil(delta)
        XCTAssertEqual(delta?.amount, 500)
        XCTAssertTrue(delta?.isPositive ?? false)
    }

    func testCalculateForAccount_WithoutPreviousBalance() {
        let account = Account(
            id: "test-2",
            name: "Test Account",
            balance: "1500.00"
        )

        let delta = AccountBalanceDelta.calculate(for: account)

        XCTAssertNil(delta)
    }

    func testCalculateForAccount_NegativeBalances() {
        // Credit card that increased debt
        let account = Account(
            id: "test-3",
            name: "Credit Card",
            balance: "-1500.00",
            accountTypeRaw: "credit card",
            previousBalance: "-1000.00"
        )

        let delta = AccountBalanceDelta.calculate(for: account)

        XCTAssertNotNil(delta)
        XCTAssertEqual(delta?.amount, -500)
        XCTAssertFalse(delta?.isPositive ?? true) // More debt is not positive
    }

    // MARK: - Formatting Tests

    func testFormatDelta_PositiveAmount() {
        let delta = AccountBalanceDelta.Delta(
            amount: 500,
            isPositive: true,
            percentageChange: 50
        )

        let formatted = AccountBalanceDelta.formatDelta(delta)

        XCTAssertTrue(formatted.hasPrefix("+"))
        XCTAssertTrue(formatted.contains("500"))
    }

    func testFormatDelta_NegativeAmount() {
        let delta = AccountBalanceDelta.Delta(
            amount: -200,
            isPositive: false,
            percentageChange: -20
        )

        let formatted = AccountBalanceDelta.formatDelta(delta)

        XCTAssertTrue(formatted.hasPrefix("-"))
        XCTAssertTrue(formatted.contains("200"))
    }

    func testFormatDelta_DifferentCurrency() {
        let delta = AccountBalanceDelta.Delta(
            amount: 100,
            isPositive: true,
            percentageChange: 10
        )

        let formatted = AccountBalanceDelta.formatDelta(delta, currencyCode: "EUR")

        XCTAssertTrue(formatted.hasPrefix("+"))
        XCTAssertTrue(formatted.contains("100"))
    }

    func testFormatPercentage_PositiveChange() {
        let delta = AccountBalanceDelta.Delta(
            amount: 500,
            isPositive: true,
            percentageChange: 50
        )

        let formatted = AccountBalanceDelta.formatPercentage(delta)

        XCTAssertNotNil(formatted)
        XCTAssertTrue(formatted?.hasPrefix("+") ?? false)
        XCTAssertTrue(formatted?.contains("50") ?? false)
    }

    func testFormatPercentage_NegativeChange() {
        let delta = AccountBalanceDelta.Delta(
            amount: -200,
            isPositive: false,
            percentageChange: -20
        )

        let formatted = AccountBalanceDelta.formatPercentage(delta)

        XCTAssertNotNil(formatted)
        XCTAssertTrue(formatted?.hasPrefix("-") ?? false)
    }

    func testFormatPercentage_NilPercentage() {
        let delta = AccountBalanceDelta.Delta(
            amount: 500,
            isPositive: true,
            percentageChange: nil
        )

        let formatted = AccountBalanceDelta.formatPercentage(delta)

        XCTAssertNil(formatted)
    }

    // MARK: - Edge Cases

    func testDeltaWithVerySmallChange() {
        let delta = AccountBalanceDelta.calculate(current: Decimal(string: "1000.01")!, previous: Decimal(string: "1000.00")!)

        XCTAssertNotNil(delta)
        XCTAssertEqual(delta?.amount, Decimal(string: "0.01"))
        XCTAssertTrue(delta?.isPositive ?? false)
    }

    func testDeltaWithLargeNumbers() {
        let delta = AccountBalanceDelta.calculate(current: 1_000_000, previous: 900_000)

        XCTAssertEqual(delta?.amount, 100_000)
        XCTAssertTrue(delta?.isPositive ?? false)
    }

    func testIsZeroProperty() {
        let zeroDelta = AccountBalanceDelta.Delta(amount: 0, isPositive: true, percentageChange: nil)
        let nonZeroDelta = AccountBalanceDelta.Delta(amount: 100, isPositive: true, percentageChange: 10)

        XCTAssertTrue(zeroDelta.isZero)
        XCTAssertFalse(nonZeroDelta.isZero)
    }
}
