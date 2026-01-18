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

        XCTAssertEqual(
            SimpleFINError.subscriptionRequired.errorDescription,
            "SimpleFIN subscription required. Please visit bridge.simplefin.org to activate or renew your subscription."
        )

        XCTAssertEqual(
            SimpleFINError.invalidCredentials.errorDescription,
            "SimpleFIN credentials are invalid. Please reconnect your account in Settings."
        )

        XCTAssertEqual(
            SimpleFINError.serverError.errorDescription,
            "SimpleFIN is temporarily unavailable. Please check your bank connections at bridge.simplefin.org and try again later."
        )
    }

    // MARK: - Server Info Decoding Tests

    func testSimpleFINServerInfoDecoding() throws {
        let json = """
        {
            "versions": ["1.0", "1.0-draft.1"]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let serverInfo = try decoder.decode(SimpleFINServerInfo.self, from: json)

        XCTAssertEqual(serverInfo.versions.count, 2)
        XCTAssertTrue(serverInfo.versions.contains("1.0"))
        XCTAssertTrue(serverInfo.versions.contains("1.0-draft.1"))
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
        // NOTE: SimpleFIN API uses hyphenated keys (sfin-url, available-balance, balance-date)
        let json = """
        {
            "errors": [],
            "accounts": [
                {
                    "id": "acc-456",
                    "org": {
                        "sfin-url": "https://bank.example.com/sfin",
                        "name": "Example Bank",
                        "domain": "bank.example.com",
                        "url": "https://bank.example.com"
                    },
                    "name": "Savings Account",
                    "currency": "USD",
                    "balance": "5000.00",
                    "available-balance": "4900.00",
                    "balance-date": 1704067200,
                    "transactions": []
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let accountSet = try decoder.decode(SimpleFINAccountSet.self, from: json)

        XCTAssertEqual(accountSet.accounts[0].org?.name, "Example Bank")
        XCTAssertEqual(accountSet.accounts[0].org?.sfinUrl, "https://bank.example.com/sfin")
        XCTAssertEqual(accountSet.accounts[0].availableBalance, "4900.00")
        XCTAssertEqual(accountSet.accounts[0].balanceDate, 1704067200)
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

        let transactions = try XCTUnwrap(accountSet.accounts[0].transactions)
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

        let transactions = try XCTUnwrap(accountSet.accounts[0].transactions)
        XCTAssertEqual(transactions[0].pending, true)
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
        // NOTE: SimpleFIN API uses hyphenated keys (cost-basis, market-value, purchase-price)
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
                            "cost-basis": "45.00",
                            "description": "Apple Inc",
                            "market-value": "178.50",
                            "purchase-price": "150.00",
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
        XCTAssertEqual(holdings[0].marketValue, "178.50")
    }

    // MARK: - Account Model Initialization Tests

    func testAccountInitFromSimpleFINAccount() throws {
        // NOTE: SimpleFIN API uses hyphenated keys
        let json = """
        {
            "errors": [],
            "accounts": [
                {
                    "id": "acc-simplefin",
                    "org": {
                        "sfin-url": "https://bank.example.com/sfin",
                        "name": "Example Bank"
                    },
                    "name": "Primary Checking",
                    "currency": "USD",
                    "balance": "2500.00",
                    "available-balance": "2400.00",
                    "balance-date": 1704067200,
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

    // MARK: - Token Whitespace Handling Tests

    func testTokenWithLeadingWhitespace() async {
        let service = SimpleFINService()

        // Token with leading spaces - should be trimmed
        let validURLBase64 = Data("https://example.com/claim/test".utf8).base64EncodedString()
        let tokenWithWhitespace = "   \(validURLBase64)"

        // This will fail at the network level (no server), but shouldn't fail at token parsing
        do {
            _ = try await service.claimSetupToken(tokenWithWhitespace)
            XCTFail("Expected network error, not token parsing error")
        } catch let error as SimpleFINError {
            // Should NOT be invalidSetupToken - whitespace should be trimmed
            XCTAssertNotEqual(error, SimpleFINError.invalidSetupToken,
                            "Token with whitespace should be trimmed, not rejected")
        } catch {
            // Network errors are expected since we can't reach the server
            // The important thing is we didn't get invalidSetupToken
        }
    }

    func testTokenWithTrailingNewline() async {
        let service = SimpleFINService()

        // Token with trailing newline (common when copying from terminal)
        let validURLBase64 = Data("https://example.com/claim/test".utf8).base64EncodedString()
        let tokenWithNewline = "\(validURLBase64)\n"

        do {
            _ = try await service.claimSetupToken(tokenWithNewline)
            XCTFail("Expected network error, not token parsing error")
        } catch let error as SimpleFINError {
            XCTAssertNotEqual(error, SimpleFINError.invalidSetupToken,
                            "Token with trailing newline should be trimmed, not rejected")
        } catch {
            // Network errors are expected
        }
    }

    // MARK: - Optional Fields Decoding Tests

    func testAccountWithoutOptionalFields() throws {
        // Minimal account with only required fields
        let json = """
        {
            "errors": [],
            "accounts": [
                {
                    "id": "acc-minimal",
                    "name": "Basic Account",
                    "currency": "USD",
                    "balance": "100.00"
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let accountSet = try decoder.decode(SimpleFINAccountSet.self, from: json)

        let account = accountSet.accounts[0]
        XCTAssertEqual(account.id, "acc-minimal")
        XCTAssertNil(account.org)
        XCTAssertNil(account.availableBalance)
        XCTAssertNil(account.balanceDate)
        XCTAssertNil(account.transactions)
        XCTAssertNil(account.holdings)
    }

    func testTransactionWithTransactedAt() throws {
        // Transaction with transacted_at field (when transaction occurred vs posted)
        let json = """
        {
            "id": "txn-with-transacted",
            "posted": 1704240000,
            "amount": "-50.00",
            "description": "RESTAURANT",
            "transacted_at": 1704200000,
            "pending": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let transaction = try decoder.decode(SimpleFINTransaction.self, from: json)

        XCTAssertEqual(transaction.posted, 1704240000)
        XCTAssertEqual(transaction.transactedAt, 1704200000)
        XCTAssertNotEqual(transaction.posted, transaction.transactedAt)
    }

    func testPendingTransactionWithZeroPostedDate() throws {
        // Per spec: pending transactions may have posted = 0
        let json = """
        {
            "id": "txn-pending-zero",
            "posted": 0,
            "amount": "-25.00",
            "description": "PENDING CHARGE",
            "pending": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let transaction = try decoder.decode(SimpleFINTransaction.self, from: json)

        XCTAssertEqual(transaction.posted, 0)
        XCTAssertEqual(transaction.pending, true)
    }

    // MARK: - Real API Response Format Test

    func testFullAPIResponseFormat() throws {
        // Test against a realistic full API response
        let json = """
        {
            "errors": [],
            "accounts": [
                {
                    "org": {
                        "domain": "mybank.com",
                        "sfin-url": "https://bridge.simplefin.org/simplefin",
                        "name": "My Bank",
                        "url": "https://www.mybank.com"
                    },
                    "id": "ACT-123456-checking",
                    "name": "PERSONAL CHECKING",
                    "currency": "USD",
                    "balance": "1234.56",
                    "available-balance": "1200.00",
                    "balance-date": 1704326400,
                    "transactions": [
                        {
                            "id": "TXN-001",
                            "posted": 1704240000,
                            "amount": "-45.67",
                            "description": "AMAZON.COM*123ABC",
                            "pending": false
                        },
                        {
                            "id": "TXN-002",
                            "posted": 0,
                            "amount": "-12.99",
                            "description": "SPOTIFY PREMIUM",
                            "pending": true
                        },
                        {
                            "id": "TXN-003",
                            "posted": 1704153600,
                            "amount": "2500.00",
                            "description": "DIRECT DEPOSIT - EMPLOYER",
                            "payee": "ACME CORP",
                            "pending": false
                        }
                    ]
                },
                {
                    "org": {
                        "domain": "mybank.com",
                        "sfin-url": "https://bridge.simplefin.org/simplefin",
                        "name": "My Bank"
                    },
                    "id": "ACT-123456-savings",
                    "name": "HIGH YIELD SAVINGS",
                    "currency": "USD",
                    "balance": "10000.00",
                    "balance-date": 1704326400,
                    "transactions": []
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let accountSet = try decoder.decode(SimpleFINAccountSet.self, from: json)

        // Verify errors array
        XCTAssertTrue(accountSet.errors.isEmpty)

        // Verify accounts
        XCTAssertEqual(accountSet.accounts.count, 2)

        // First account - checking with transactions
        let checking = accountSet.accounts[0]
        XCTAssertEqual(checking.id, "ACT-123456-checking")
        XCTAssertEqual(checking.name, "PERSONAL CHECKING")
        XCTAssertEqual(checking.balance, "1234.56")
        XCTAssertEqual(checking.availableBalance, "1200.00")
        XCTAssertEqual(checking.org?.name, "My Bank")
        XCTAssertEqual(checking.org?.domain, "mybank.com")

        let transactions = try XCTUnwrap(checking.transactions)
        XCTAssertEqual(transactions.count, 3)

        // Verify pending transaction with posted=0
        let pendingTxn = transactions[1]
        XCTAssertEqual(pendingTxn.posted, 0)
        XCTAssertEqual(pendingTxn.pending, true)

        // Verify transaction with payee
        let depositTxn = transactions[2]
        XCTAssertEqual(depositTxn.payee, "ACME CORP")
        XCTAssertEqual(depositTxn.amount, "2500.00")

        // Second account - savings with empty transactions
        let savings = accountSet.accounts[1]
        XCTAssertEqual(savings.id, "ACT-123456-savings")
        XCTAssertEqual(savings.accountTypeRaw, "savings")
        XCTAssertNil(savings.availableBalance) // Not provided
        XCTAssertEqual(savings.transactions?.count, 0)
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
        case (.invalidSetupToken, .invalidSetupToken),
             (.tokenAlreadyClaimed, .tokenAlreadyClaimed),
             (.noAccessToken, .noAccessToken),
             (.invalidAccessURL, .invalidAccessURL),
             (.invalidResponse, .invalidResponse),
             (.rateLimited, .rateLimited),
             (.subscriptionRequired, .subscriptionRequired),
             (.invalidCredentials, .invalidCredentials),
             (.serverError, .serverError):
            return true
        case let (.claimFailed(lCode), .claimFailed(rCode)),
             let (.fetchFailed(lCode), .fetchFailed(rCode)):
            return lCode == rCode
        default:
            return false
        }
    }
}
