//
//  AuthErrorTests.swift
//  OSRPTests
//
//  Unit tests for AuthError
//

import XCTest
@testable import OSRP

final class AuthErrorTests: XCTestCase {

    func testInvalidCredentialsError() {
        let error = AuthError.invalidCredentials
        XCTAssertEqual(error.errorDescription, "Invalid email or password")
    }

    func testNetworkError() {
        let error = AuthError.networkError
        XCTAssertEqual(error.errorDescription, "Network connection error. Please check your internet connection.")
    }

    func testServerError() {
        let message = "Server is temporarily unavailable"
        let error = AuthError.serverError(message)
        XCTAssertEqual(error.errorDescription, message)
    }

    func testTokenExpiredError() {
        let error = AuthError.tokenExpired
        XCTAssertEqual(error.errorDescription, "Your session has expired. Please login again.")
    }

    func testInvalidResponseError() {
        let error = AuthError.invalidResponse
        XCTAssertEqual(error.errorDescription, "Invalid response from server")
    }

    func testKeychainError() {
        let keychainError = KeychainError.itemNotFound
        let error = AuthError.keychainError(keychainError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Keychain error"))
    }

    func testUnknownError() {
        let underlyingError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let error = AuthError.unknown(underlyingError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Test error"))
    }
}
