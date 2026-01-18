//
//  AccountTests.swift
//  GhostVaultTests
//
//  Unit tests for Account model
//

import XCTest
@testable import GhostVault

final class AccountTests: XCTestCase {

    // MARK: - Balance Value Tests

    func testBalanceValueParsesPositiveDecimal() {
        let account = Account(
            id: "test-1",
            name: "Checking",
            balance: "1234.56"
        )
        XCTAssertEqual(account.balanceValue, Decimal(string: "1234.56"))
    }

    func testBalanceValueParsesNegativeDecimal() {
        let account = Account(
            id: "test-2",
            name: "Credit Card",
            balance: "-500.00"
        )
        XCTAssertEqual(account.balanceValue, Decimal(string: "-500.00"))
    }

    func testBalanceValueReturnsZeroForInvalidString() {
        let account = Account(
            id: "test-3",
            name: "Invalid",
            balance: "not-a-number"
        )
        XCTAssertEqual(account.balanceValue, Decimal(0))
    }

    func testBalanceValueHandlesLargeNumbers() {
        let account = Account(
            id: "test-4",
            name: "Investment",
            balance: "1234567890.12"
        )
        XCTAssertEqual(account.balanceValue, Decimal(string: "1234567890.12"))
    }

    // MARK: - Available Balance Tests

    func testAvailableBalanceValueReturnsNilWhenNotSet() {
        let account = Account(
            id: "test-5",
            name: "Checking",
            balance: "1000.00",
            availableBalance: nil
        )
        XCTAssertNil(account.availableBalanceValue)
    }

    func testAvailableBalanceValueParsesCorrectly() {
        let account = Account(
            id: "test-6",
            name: "Checking",
            balance: "1000.00",
            availableBalance: "950.00"
        )
        XCTAssertEqual(account.availableBalanceValue, Decimal(string: "950.00"))
    }

    // MARK: - Account Type Classification Tests

    func testAccountTypeChecking() {
        let account = Account(
            id: "test-7",
            name: "My Checking",
            balance: "500.00",
            accountTypeRaw: "checking"
        )
        XCTAssertEqual(account.accountType, .checking)
        XCTAssertEqual(account.accountType.displayName, "Checking")
        XCTAssertEqual(account.accountType.iconName, "banknote")
    }

    func testAccountTypeSavings() {
        let account = Account(
            id: "test-8",
            name: "Savings",
            balance: "5000.00",
            accountTypeRaw: "savings"
        )
        XCTAssertEqual(account.accountType, .savings)
        XCTAssertEqual(account.accountType.displayName, "Savings")
        XCTAssertEqual(account.accountType.iconName, "building.columns")
    }

    func testAccountTypeCreditCard() {
        let account = Account(
            id: "test-9",
            name: "Rewards Card",
            balance: "-1500.00",
            accountTypeRaw: "credit card"
        )
        XCTAssertEqual(account.accountType, .creditCard)
        XCTAssertEqual(account.accountType.displayName, "Credit Card")
        XCTAssertEqual(account.accountType.iconName, "creditcard")
    }

    func testAccountTypeInvestment() {
        let account = Account(
            id: "test-10",
            name: "Brokerage",
            balance: "50000.00",
            accountTypeRaw: "investment"
        )
        XCTAssertEqual(account.accountType, .investment)
        XCTAssertEqual(account.accountType.displayName, "Investment")
    }

    func testAccountTypeLoan() {
        let account = Account(
            id: "test-11",
            name: "Auto Loan",
            balance: "-15000.00",
            accountTypeRaw: "loan"
        )
        XCTAssertEqual(account.accountType, .loan)
        XCTAssertEqual(account.accountType.displayName, "Loan")
    }

    func testAccountTypeMortgage() {
        let account = Account(
            id: "test-12",
            name: "Home Mortgage",
            balance: "-250000.00",
            accountTypeRaw: "mortgage"
        )
        XCTAssertEqual(account.accountType, .mortgage)
        XCTAssertEqual(account.accountType.displayName, "Mortgage")
    }

    func testAccountTypeUnknownForInvalidRaw() {
        let account = Account(
            id: "test-13",
            name: "Unknown Account",
            balance: "100.00",
            accountTypeRaw: "not-a-valid-type"
        )
        XCTAssertEqual(account.accountType, .unknown)
        XCTAssertEqual(account.accountType.displayName, "Other")
    }

    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        let account = Account(
            id: "test-14",
            name: "Test Account",
            balance: "100.00"
        )

        XCTAssertEqual(account.id, "test-14")
        XCTAssertEqual(account.name, "Test Account")
        XCTAssertEqual(account.balance, "100.00")
        XCTAssertNil(account.organizationId)
        XCTAssertNil(account.organizationName)
        XCTAssertEqual(account.currency, "USD")
        XCTAssertNil(account.availableBalance)
        XCTAssertNil(account.balanceDate)
        XCTAssertEqual(account.accountTypeRaw, "unknown")
    }

    func testFullInitialization() {
        let balanceDate = Date()
        let account = Account(
            id: "test-15",
            organizationId: "org-123",
            organizationName: "Test Bank",
            name: "Premium Checking",
            currency: "EUR",
            balance: "2500.00",
            availableBalance: "2400.00",
            balanceDate: balanceDate,
            accountTypeRaw: "checking"
        )

        XCTAssertEqual(account.organizationId, "org-123")
        XCTAssertEqual(account.organizationName, "Test Bank")
        XCTAssertEqual(account.currency, "EUR")
        XCTAssertEqual(account.availableBalance, "2400.00")
        XCTAssertEqual(account.balanceDate, balanceDate)
    }
}
