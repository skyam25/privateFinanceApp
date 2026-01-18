//
//  AccountFilterTests.swift
//  GhostVaultTests
//
//  Unit tests for AccountFilter logic
//

import XCTest
@testable import GhostVault

final class AccountFilterTests: XCTestCase {

    // MARK: - Test Data

    private var sampleAccounts: [DiscoveredAccount] {
        [
            DiscoveredAccount(
                id: "1",
                name: "Main Checking",
                organizationName: "Chase Bank",
                type: "checking",
                balance: "1500.00",
                currency: "USD",
                isIncluded: true
            ),
            DiscoveredAccount(
                id: "2",
                name: "Savings",
                organizationName: "Chase Bank",
                type: "savings",
                balance: "5000.00",
                currency: "USD",
                isIncluded: true
            ),
            DiscoveredAccount(
                id: "3",
                name: "Travel Card",
                organizationName: "Amex",
                type: "credit card",
                balance: "-500.00",
                currency: "USD",
                isIncluded: false
            ),
            DiscoveredAccount(
                id: "4",
                name: "401k",
                organizationName: "Fidelity",
                type: "investment",
                balance: "50000.00",
                currency: "USD",
                isIncluded: true
            )
        ]
    }

    // MARK: - Filter Included Tests

    func testFilterIncludedReturnsOnlyIncludedAccounts() {
        let filtered = AccountFilter.filterIncluded(sampleAccounts)

        XCTAssertEqual(filtered.count, 3)
        XCTAssertTrue(filtered.allSatisfy { $0.isIncluded })
    }

    func testFilterIncludedWithAllExcludedReturnsEmpty() {
        var accounts = sampleAccounts
        for i in 0..<accounts.count {
            accounts[i].isIncluded = false
        }

        let filtered = AccountFilter.filterIncluded(accounts)

        XCTAssertTrue(filtered.isEmpty)
    }

    func testFilterIncludedWithAllIncludedReturnsAll() {
        var accounts = sampleAccounts
        for i in 0..<accounts.count {
            accounts[i].isIncluded = true
        }

        let filtered = AccountFilter.filterIncluded(accounts)

        XCTAssertEqual(filtered.count, accounts.count)
    }

    func testFilterIncludedWithEmptyArrayReturnsEmpty() {
        let filtered = AccountFilter.filterIncluded([])

        XCTAssertTrue(filtered.isEmpty)
    }

    // MARK: - Total Balance Tests

    func testTotalBalanceCalculatesOnlyIncluded() {
        let total = AccountFilter.totalBalance(sampleAccounts)

        // 1500 + 5000 + 50000 = 56500 (excludes -500 credit card)
        XCTAssertEqual(total, Decimal(string: "56500.00"))
    }

    func testTotalBalanceWithNegativeBalances() {
        var accounts = sampleAccounts
        // Include the credit card
        accounts[2].isIncluded = true

        let total = AccountFilter.totalBalance(accounts)

        // 1500 + 5000 - 500 + 50000 = 56000
        XCTAssertEqual(total, Decimal(string: "56000.00"))
    }

    func testTotalBalanceWithNoIncludedReturnsZero() {
        var accounts = sampleAccounts
        for i in 0..<accounts.count {
            accounts[i].isIncluded = false
        }

        let total = AccountFilter.totalBalance(accounts)

        XCTAssertEqual(total, 0)
    }

    func testTotalBalanceWithEmptyArrayReturnsZero() {
        let total = AccountFilter.totalBalance([])

        XCTAssertEqual(total, 0)
    }

    // MARK: - Group By Type Tests

    func testGroupByTypeCreatesCorrectGroups() {
        let grouped = AccountFilter.groupByType(sampleAccounts)

        XCTAssertEqual(grouped.keys.count, 4)
        XCTAssertEqual(grouped["checking"]?.count, 1)
        XCTAssertEqual(grouped["savings"]?.count, 1)
        XCTAssertEqual(grouped["credit card"]?.count, 1)
        XCTAssertEqual(grouped["investment"]?.count, 1)
    }

    func testGroupByTypeWithMultipleOfSameType() {
        var accounts = sampleAccounts
        accounts.append(DiscoveredAccount(
            id: "5",
            name: "Business Checking",
            organizationName: "Chase Bank",
            type: "checking",
            balance: "2000.00",
            currency: "USD",
            isIncluded: true
        ))

        let grouped = AccountFilter.groupByType(accounts)

        XCTAssertEqual(grouped["checking"]?.count, 2)
    }

    func testGroupByTypeWithEmptyArrayReturnsEmptyDict() {
        let grouped = AccountFilter.groupByType([])

        XCTAssertTrue(grouped.isEmpty)
    }

    // MARK: - Filter By Organization Tests

    func testFilterByOrganizationFindsMatchingAccounts() {
        let filtered = AccountFilter.filterByOrganization(sampleAccounts, organization: "Chase")

        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.organizationName.contains("Chase") })
    }

    func testFilterByOrganizationIsCaseInsensitive() {
        let filtered = AccountFilter.filterByOrganization(sampleAccounts, organization: "chase")

        XCTAssertEqual(filtered.count, 2)
    }

    func testFilterByOrganizationWithPartialMatch() {
        let filtered = AccountFilter.filterByOrganization(sampleAccounts, organization: "Fidel")

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.organizationName, "Fidelity")
    }

    func testFilterByOrganizationWithNoMatchReturnsEmpty() {
        let filtered = AccountFilter.filterByOrganization(sampleAccounts, organization: "Unknown Bank")

        XCTAssertTrue(filtered.isEmpty)
    }

    func testFilterByOrganizationWithEmptyArrayReturnsEmpty() {
        let filtered = AccountFilter.filterByOrganization([], organization: "Chase")

        XCTAssertTrue(filtered.isEmpty)
    }
}
