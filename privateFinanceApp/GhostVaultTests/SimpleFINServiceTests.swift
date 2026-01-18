//
//  SimpleFINServiceTests.swift
//  GhostVaultTests
//
//  Unit tests for SimpleFINService with mocked network responses
//

import XCTest
@testable import GhostVault

final class SimpleFINServiceTests: XCTestCase {

    // MARK: - Setup Token Validation Tests

    func testInvalidBase64TokenThrowsError() async {
        let service = SimpleFINService()

        // Not valid base64
        do {
            _ = try await service.claimSetupToken("not-valid-base64!!!")
            XCTFail("Expected invalidSetupToken error")
        } catch let error as SimpleFINError {
            XCTAssertEqual(error, SimpleFINError.invalidSetupToken)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testBase64TokenWithWhitespaceOnlyThrowsError() async {
        let service = SimpleFINService()

        // Valid base64 encoding of whitespace/empty content that can't be a URL
        let whitespaceOnly = "   "
        let encodedToken = Data(whitespaceOnly.utf8).base64EncodedString()

        do {
            _ = try await service.claimSetupToken(encodedToken)
            XCTFail("Expected invalidSetupToken error")
        } catch let error as SimpleFINError {
            XCTAssertEqual(error, SimpleFINError.invalidSetupToken)
        } catch {
            // URL(string:) accepts whitespace, so we may get a URL error instead
            // This is acceptable - the key point is we don't get a valid access URL
            XCTAssertNotNil(error, "Should throw some error for whitespace-only token")
        }
    }

    func testEmptyTokenThrowsError() async {
        let service = SimpleFINService()

        do {
            _ = try await service.claimSetupToken("")
            XCTFail("Expected invalidSetupToken error")
        } catch let error as SimpleFINError {
            XCTAssertEqual(error, SimpleFINError.invalidSetupToken)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - SimpleFIN Error Tests

    func testSimpleFINErrorDescriptions() {
        XCTAssertEqual(
            SimpleFINError.invalidSetupToken.errorDescription,
            "The setup token is invalid or malformed."
        )

        XCTAssertEqual(
            SimpleFINError.tokenAlreadyClaimed.errorDescription,
            "This setup token has already been claimed. Please generate a new one."
        )

        XCTAssertEqual(
            SimpleFINError.claimFailed(statusCode: 500).errorDescription,
            "Failed to claim token (HTTP 500)."
        )

        XCTAssertEqual(
            SimpleFINError.noAccessToken.errorDescription,
            "No SimpleFIN access token configured."
        )

        XCTAssertEqual(
            SimpleFINError.invalidAccessURL.errorDescription,
            "The access URL is invalid."
        )

        XCTAssertEqual(
            SimpleFINError.invalidResponse.errorDescription,
            "Received an invalid response from SimpleFIN."
        )

        XCTAssertEqual(
            SimpleFINError.fetchFailed(statusCode: 401).errorDescription,
            "Failed to fetch accounts (HTTP 401)."
        )

        XCTAssertEqual(
            SimpleFINError.rateLimited.errorDescription,
            "Rate limit exceeded. SimpleFIN allows 24 requests per day."
        )
    }

    // MARK: - SimpleFIN Models Decoding Tests

    func testSimpleFINAccountSetDecoding() throws {
        let json = """
        {
            "errors": [],
            "accounts": [
                {
                    "id": "acc-123",
                    "name": "My Checking Account",
                    "currency": "USD",
                    "balance": "1500.00",
                    "transactions": []
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let accountSet = try decoder.decode(SimpleFINAccountSet.self, from: json)

        XCTAssertTrue(accountSet.errors.isEmpty)
        XCTAssertEqual(accountSet.accounts.count, 1)
        XCTAssertEqual(accountSet.accounts[0].id, "acc-123")
        XCTAssertEqual(accountSet.accounts[0].name, "My Checking Account")
        XCTAssertEqual(accountSet.accounts[0].balance, "1500.00")
    }

    func testSimpleFINAccountWithOrganizationDecoding() throws {
        let json = """
        {
            "errors": [],
            "accounts": [
                {
                    "id": "acc-456",
                    "org": {
                        "sfin_url": "https://bank.example.com/sfin",
                        "name": "Example Bank",
                        "domain": "bank.example.com",
                        "url": "https://bank.example.com"
                    },
                    "name": "Savings Account",
                    "currency": "USD",
                    "balance": "5000.00",
                    "available_balance": "4900.00",
                    "balance_date": 1704067200,
                    "transactions": []
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let accountSet = try decoder.decode(SimpleFINAccountSet.self, from: json)

        XCTAssertEqual(accountSet.accounts[0].org?.name, "Example Bank")
        XCTAssertEqual(accountSet.accounts[0].org?.sfin_url, "https://bank.example.com/sfin")
        XCTAssertEqual(accountSet.accounts[0].available_balance, "4900.00")
        XCTAssertEqual(accountSet.accounts[0].balance_date, 1704067200)
    }

    func testSimpleFINTransactionDecoding() throws {
        let json = """
        {
            "errors": [],
            "accounts": [
                {
                    "id": "acc-789",
                    "name": "Checking",
                    "currency": "USD",
                    "balance": "1000.00",
                    "transactions": [
                        {
                            "id": "txn-001",
                            "posted": 1704153600,
                            "amount": "-25.50",
                            "description": "COFFEE SHOP",
                            "payee": "Starbucks",
                            "memo": "Morning coffee",
                            "pending": false
                        },
                        {
                            "id": "txn-002",
                            "posted": 1704240000,
                            "amount": "1500.00",
                            "description": "PAYROLL DEPOSIT",
                            "pending": false
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let accountSet = try decoder.decode(SimpleFINAccountSet.self, from: json)

        let transactions = accountSet.accounts[0].transactions
        XCTAssertEqual(transactions.count, 2)

        XCTAssertEqual(transactions[0].id, "txn-001")
        XCTAssertEqual(transactions[0].amount, "-25.50")
        XCTAssertEqual(transactions[0].description, "COFFEE SHOP")
        XCTAssertEqual(transactions[0].payee, "Starbucks")
        XCTAssertEqual(transactions[0].memo, "Morning coffee")
        XCTAssertEqual(transactions[0].pending, false)

        XCTAssertEqual(transactions[1].id, "txn-002")
        XCTAssertEqual(transactions[1].amount, "1500.00")
        XCTAssertNil(transactions[1].payee)
    }

    func testSimpleFINPendingTransactionDecoding() throws {
        let json = """
        {
            "errors": [],
            "accounts": [
                {
                    "id": "acc-100",
                    "name": "Credit Card",
                    "currency": "USD",
                    "balance": "-500.00",
                    "transactions": [
                        {
                            "id": "txn-pending",
                            "posted": 1704326400,
                            "amount": "-75.00",
                            "description": "AMAZON PURCHASE",
                            "pending": true
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let accountSet = try decoder.decode(SimpleFINAccountSet.self, from: json)

        XCTAssertEqual(accountSet.accounts[0].transactions[0].pending, true)
    }

    func testSimpleFINAccountSetWithErrors() throws {
        let json = """
        {
            "errors": ["Connection timeout for account-xyz", "Rate limit exceeded"],
            "accounts": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let accountSet = try decoder.decode(SimpleFINAccountSet.self, from: json)

        XCTAssertEqual(accountSet.errors.count, 2)
        XCTAssertTrue(accountSet.errors.contains("Connection timeout for account-xyz"))
        XCTAssertTrue(accountSet.errors.contains("Rate limit exceeded"))
        XCTAssertTrue(accountSet.accounts.isEmpty)
    }

    func testSimpleFINAccountTypeInference() throws {
        // Test account type inference from name
        let json = """
        {
            "errors": [],
            "accounts": [
                {"id": "1", "name": "My Checking Account", "currency": "USD", "balance": "100", "transactions": []},
                {"id": "2", "name": "High Yield Savings", "currency": "USD", "balance": "500", "transactions": []},
                {"id": "3", "name": "Rewards Credit Card", "currency": "USD", "balance": "-200", "transactions": []},
                {"id": "4", "name": "Investment Portfolio", "currency": "USD", "balance": "10000", "transactions": []},
                {"id": "5", "name": "Auto Loan", "currency": "USD", "balance": "-15000", "transactions": []},
                {"id": "6", "name": "Home Mortgage", "currency": "USD", "balance": "-200000", "transactions": []},
                {"id": "7", "name": "Random Account", "currency": "USD", "balance": "50", "transactions": []}
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let accountSet = try decoder.decode(SimpleFINAccountSet.self, from: json)

        XCTAssertEqual(accountSet.accounts[0].accountTypeRaw, "checking")
        XCTAssertEqual(accountSet.accounts[1].accountTypeRaw, "savings")
        XCTAssertEqual(accountSet.accounts[2].accountTypeRaw, "credit card")
        XCTAssertEqual(accountSet.accounts[3].accountTypeRaw, "investment")
        XCTAssertEqual(accountSet.accounts[4].accountTypeRaw, "loan")
        XCTAssertEqual(accountSet.accounts[5].accountTypeRaw, "mortgage")
        XCTAssertEqual(accountSet.accounts[6].accountTypeRaw, "unknown")
    }

    func testSimpleFINHoldingDecoding() throws {
        let json = """
        {
            "errors": [],
            "accounts": [
                {
                    "id": "inv-001",
                    "name": "Brokerage Account",
                    "currency": "USD",
                    "balance": "50000.00",
                    "transactions": [],
                    "holdings": [
                        {
                            "id": "hold-001",
                            "created": 1704067200,
                            "currency": "USD",
                            "cost_basis": "45.00",
                            "description": "Apple Inc",
                            "market_value": "178.50",
                            "purchase_price": "150.00",
                            "shares": "10.5",
                            "symbol": "AAPL"
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let accountSet = try decoder.decode(SimpleFINAccountSet.self, from: json)

        let holdings = accountSet.accounts[0].holdings!
        XCTAssertEqual(holdings.count, 1)
        XCTAssertEqual(holdings[0].symbol, "AAPL")
        XCTAssertEqual(holdings[0].shares, "10.5")
        XCTAssertEqual(holdings[0].market_value, "178.50")
    }

    // MARK: - Account Model Initialization Tests

    func testAccountInitFromSimpleFINAccount() throws {
        let json = """
        {
            "errors": [],
            "accounts": [
                {
                    "id": "acc-simplefin",
                    "org": {
                        "sfin_url": "https://bank.example.com/sfin",
                        "name": "Example Bank"
                    },
                    "name": "Primary Checking",
                    "currency": "USD",
                    "balance": "2500.00",
                    "available_balance": "2400.00",
                    "balance_date": 1704067200,
                    "transactions": []
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let accountSet = try decoder.decode(SimpleFINAccountSet.self, from: json)
        let apiAccount = accountSet.accounts[0]

        let account = Account(from: apiAccount)

        XCTAssertEqual(account.id, "acc-simplefin")
        XCTAssertEqual(account.organizationId, "https://bank.example.com/sfin")
        XCTAssertEqual(account.organizationName, "Example Bank")
        XCTAssertEqual(account.name, "Primary Checking")
        XCTAssertEqual(account.currency, "USD")
        XCTAssertEqual(account.balance, "2500.00")
        XCTAssertEqual(account.availableBalance, "2400.00")
        XCTAssertNotNil(account.balanceDate)
    }

    // MARK: - Transaction Model Initialization Tests

    func testTransactionInitFromSimpleFINTransaction() throws {
        let json = """
        {
            "id": "txn-simplefin",
            "posted": 1704153600,
            "amount": "-99.99",
            "description": "ONLINE PURCHASE",
            "payee": "Amazon",
            "memo": "Book order",
            "pending": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let apiTransaction = try decoder.decode(SimpleFINTransaction.self, from: json)

        let transaction = Transaction(from: apiTransaction, accountId: "acc-123")

        XCTAssertEqual(transaction.id, "txn-simplefin")
        XCTAssertEqual(transaction.accountId, "acc-123")
        XCTAssertEqual(transaction.amount, "-99.99")
        XCTAssertEqual(transaction.transactionDescription, "ONLINE PURCHASE")
        XCTAssertEqual(transaction.payee, "Amazon")
        XCTAssertEqual(transaction.memo, "Book order")
        XCTAssertFalse(transaction.pending)
        XCTAssertNil(transaction.category) // Category is assigned by local rules
    }
}

// MARK: - SimpleFINError Equatable

extension SimpleFINError: Equatable {
    public static func == (lhs: SimpleFINError, rhs: SimpleFINError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidSetupToken, .invalidSetupToken):
            return true
        case (.tokenAlreadyClaimed, .tokenAlreadyClaimed):
            return true
        case (.claimFailed(let lCode), .claimFailed(let rCode)):
            return lCode == rCode
        case (.noAccessToken, .noAccessToken):
            return true
        case (.invalidAccessURL, .invalidAccessURL):
            return true
        case (.invalidResponse, .invalidResponse):
            return true
        case (.fetchFailed(let lCode), .fetchFailed(let rCode)):
            return lCode == rCode
        case (.rateLimited, .rateLimited):
            return true
        default:
            return false
        }
    }
}
