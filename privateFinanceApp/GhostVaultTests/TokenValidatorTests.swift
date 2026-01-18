//
//  TokenValidatorTests.swift
//  GhostVaultTests
//
//  Unit tests for TokenValidator format validation
//

import XCTest
@testable import GhostVault

final class TokenValidatorTests: XCTestCase {

    // MARK: - Empty Token Tests

    func testEmptyTokenIsInvalid() {
        let result = TokenValidator.validate("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Please enter a setup token.")
    }

    func testWhitespaceOnlyTokenIsInvalid() {
        let result = TokenValidator.validate("   \n\t  ")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Please enter a setup token.")
    }

    // MARK: - Token Length Tests

    func testShortTokenIsInvalid() {
        let result = TokenValidator.validate("abc123")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Token appears too short. Please check and try again.")
    }

    func testTokenAtMinimumLengthButInvalidBase64() {
        let result = TokenValidator.validate("12345678901234567890!!!")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Invalid token format. Make sure you copied the entire token.")
    }

    // MARK: - Base64 Format Tests

    func testInvalidBase64IsRejected() {
        // Invalid base64 characters
        let result = TokenValidator.validate("not-valid-base64-at-all!!@@##")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Invalid token format. Make sure you copied the entire token.")
    }

    func testValidBase64ButNotURLIsRejected() {
        // Base64 encoding of a long string that is not a valid http/https URL
        let notAURL = "this is just some random text that is not a valid URL with http or https scheme"
        let encoded = Data(notAURL.utf8).base64EncodedString()
        let result = TokenValidator.validate(encoded)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Token does not contain a valid URL. Please get a new token from SimpleFIN.")
    }

    func testValidBase64WithNonUTF8DataIsRejected() {
        // Create base64 from invalid UTF-8 bytes
        let invalidBytes: [UInt8] = [0xFF, 0xFE, 0x00, 0x01, 0xFF, 0xFF, 0xFE, 0xFE,
                                      0x00, 0x01, 0xFF, 0xFF, 0xFE, 0xFE, 0x00, 0x01,
                                      0xFF, 0xFF, 0xFE, 0xFE, 0x00, 0x01, 0xFF, 0xFF]
        let encoded = Data(invalidBytes).base64EncodedString()
        let result = TokenValidator.validate(encoded)
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Valid Token Tests

    func testValidTokenWithHTTPSURLIsAccepted() {
        // Base64 encoding of a valid HTTPS URL
        let url = "https://api.simplefin.org/claim/abc123"
        let encoded = Data(url.utf8).base64EncodedString()
        let result = TokenValidator.validate(encoded)
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testValidTokenWithHTTPURLIsAccepted() {
        // Base64 encoding of a valid HTTP URL
        let url = "http://bridge.simplefin.org/claim/token"
        let encoded = Data(url.utf8).base64EncodedString()
        let result = TokenValidator.validate(encoded)
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testTokenWithWhitespacePaddingIsAccepted() {
        // Token with whitespace around it should be trimmed
        let url = "https://api.simplefin.org/claim/abc123"
        let encoded = "  " + Data(url.utf8).base64EncodedString() + "\n  "
        let result = TokenValidator.validate(encoded)
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testTokenWithComplexURLIsAccepted() {
        // More complex URL with path and query params
        let url = "https://bridge.simplefin.org/simplefin/claim/abc123?redirect=true"
        let encoded = Data(url.utf8).base64EncodedString()
        let result = TokenValidator.validate(encoded)
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    // MARK: - Edge Cases

    func testTokenWithNewlinesInMiddleIsInvalid() {
        // Base64 should not have newlines in the middle
        let url = "https://api.simplefin.org/claim/abc123"
        let encoded = Data(url.utf8).base64EncodedString()
        let brokenEncoded = String(encoded.prefix(10)) + "\n" + String(encoded.dropFirst(10))
        let result = TokenValidator.validate(brokenEncoded)
        // This should fail because the newline breaks the base64
        XCTAssertFalse(result.isValid)
    }

    func testValidationResultStructure() {
        let validResult = TokenValidator.ValidationResult(isValid: true, errorMessage: nil)
        XCTAssertTrue(validResult.isValid)
        XCTAssertNil(validResult.errorMessage)

        let invalidResult = TokenValidator.ValidationResult(isValid: false, errorMessage: "Test error")
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertEqual(invalidResult.errorMessage, "Test error")
    }
}
