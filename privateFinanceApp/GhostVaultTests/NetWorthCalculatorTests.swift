//
//  NetWorthCalculatorTests.swift
//  GhostVaultTests
//
//  Unit tests for net worth calculation logic
//

import XCTest
@testable import GhostVault

final class NetWorthCalculatorTests: XCTestCase {

    // MARK: - Basic Calculations

    func testNetWorthWithNoAccounts() {
        let result = NetWorthCalculator.calculate(accounts: [])

        XCTAssertEqual(result.netWorth, 0)
        XCTAssertEqual(result.totalAssets, 0)
        XCTAssertEqual(result.totalLiabilities, 0)
    }

    func testNetWorthWithSingleAsset() {
        let accounts = [
            makeAccount(id: "1", balance: "1000.00", type: .checking)
        ]

        let result = NetWorthCalculator.calculate(accounts: accounts)

        XCTAssertEqual(result.netWorth, 1000)
        XCTAssertEqual(result.totalAssets, 1000)
        XCTAssertEqual(result.totalLiabilities, 0)
    }

    func testNetWorthWithSingleLiability() {
        let accounts = [
            makeAccount(id: "1", balance: "-500.00", type: .creditCard)
        ]

        let result = NetWorthCalculator.calculate(accounts: accounts)

        XCTAssertEqual(result.netWorth, -500)
        XCTAssertEqual(result.totalAssets, 0)
        XCTAssertEqual(result.totalLiabilities, 500)
    }

    func testNetWorthWithMixedAccounts() {
        let accounts = [
            makeAccount(id: "1", balance: "5000.00", type: .checking),
            makeAccount(id: "2", balance: "10000.00", type: .savings),
            makeAccount(id: "3", balance: "-2000.00", type: .creditCard),
            makeAccount(id: "4", balance: "-150000.00", type: .mortgage)
        ]

        let result = NetWorthCalculator.calculate(accounts: accounts)

        XCTAssertEqual(result.totalAssets, 15000)
        XCTAssertEqual(result.totalLiabilities, 152000)
        XCTAssertEqual(result.netWorth, -137000)
    }

    // MARK: - Hidden Accounts

    func testHiddenAccountsAreExcluded() {
        let accounts = [
            makeAccount(id: "1", balance: "5000.00", type: .checking),
            makeAccount(id: "2", balance: "10000.00", type: .savings, isHidden: true)
        ]

        let result = NetWorthCalculator.calculate(accounts: accounts)

        XCTAssertEqual(result.netWorth, 5000)
        XCTAssertEqual(result.totalAssets, 5000)
    }

    func testHiddenLiabilitiesAreExcluded() {
        let accounts = [
            makeAccount(id: "1", balance: "-2000.00", type: .creditCard),
            makeAccount(id: "2", balance: "-5000.00", type: .loan, isHidden: true)
        ]

        let result = NetWorthCalculator.calculate(accounts: accounts)

        XCTAssertEqual(result.totalLiabilities, 2000)
    }

    // MARK: - Account Type Classification

    func testCheckingIsAsset() {
        XCTAssertTrue(NetWorthCalculator.isAssetType(.checking))
    }

    func testSavingsIsAsset() {
        XCTAssertTrue(NetWorthCalculator.isAssetType(.savings))
    }

    func testInvestmentIsAsset() {
        XCTAssertTrue(NetWorthCalculator.isAssetType(.investment))
    }

    func testCreditCardIsLiability() {
        XCTAssertFalse(NetWorthCalculator.isAssetType(.creditCard))
    }

    func testLoanIsLiability() {
        XCTAssertFalse(NetWorthCalculator.isAssetType(.loan))
    }

    func testMortgageIsLiability() {
        XCTAssertFalse(NetWorthCalculator.isAssetType(.mortgage))
    }

    func testUnknownDefaultsToAsset() {
        // Unknown accounts with positive balance treated as assets
        XCTAssertTrue(NetWorthCalculator.isAssetType(.unknown))
    }

    // MARK: - Edge Cases

    func testZeroBalanceAccounts() {
        let accounts = [
            makeAccount(id: "1", balance: "0.00", type: .checking),
            makeAccount(id: "2", balance: "0.00", type: .creditCard)
        ]

        let result = NetWorthCalculator.calculate(accounts: accounts)

        XCTAssertEqual(result.netWorth, 0)
        XCTAssertEqual(result.totalAssets, 0)
        XCTAssertEqual(result.totalLiabilities, 0)
    }

    func testInvalidBalanceStringTreatedAsZero() {
        let accounts = [
            makeAccount(id: "1", balance: "invalid", type: .checking)
        ]

        let result = NetWorthCalculator.calculate(accounts: accounts)

        XCTAssertEqual(result.netWorth, 0)
    }

    func testLargeBalances() {
        let accounts = [
            makeAccount(id: "1", balance: "1234567890.12", type: .investment)
        ]

        let result = NetWorthCalculator.calculate(accounts: accounts)

        XCTAssertEqual(result.netWorth, Decimal(string: "1234567890.12"))
    }

    // MARK: - Delta Calculation

    func testDeltaWithPositiveChange() {
        let delta = NetWorthCalculator.calculateDelta(current: 10000, previous: 8000)

        XCTAssertEqual(delta.amount, 2000)
        XCTAssertTrue(delta.isPositive)
        XCTAssertEqual(delta.percentageChange, 25) // 2000/8000 = 0.25 = 25%
    }

    func testDeltaWithNegativeChange() {
        let delta = NetWorthCalculator.calculateDelta(current: 8000, previous: 10000)

        XCTAssertEqual(delta.amount, -2000)
        XCTAssertFalse(delta.isPositive)
        XCTAssertEqual(delta.percentageChange, -20) // -2000/10000 = -0.2 = -20%
    }

    func testDeltaWithZeroPrevious() {
        let delta = NetWorthCalculator.calculateDelta(current: 5000, previous: 0)

        XCTAssertEqual(delta.amount, 5000)
        XCTAssertNil(delta.percentageChange) // Can't calculate % from zero
    }

    func testDeltaWithNoChange() {
        let delta = NetWorthCalculator.calculateDelta(current: 5000, previous: 5000)

        XCTAssertEqual(delta.amount, 0)
        XCTAssertEqual(delta.percentageChange, 0)
    }

    // MARK: - Helpers

    private func makeAccount(
        id: String,
        balance: String,
        type: AccountType,
        isHidden: Bool = false
    ) -> Account {
        Account(
            id: id,
            name: "Test Account",
            balance: balance,
            accountTypeRaw: type.rawValue,
            isHidden: isHidden
        )
    }
}
