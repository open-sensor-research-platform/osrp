//
//  KeychainManagerTests.swift
//  OSRPTests
//
//  Unit tests for KeychainManager
//

import XCTest
@testable import OSRP

final class KeychainManagerTests: XCTestCase {
    var keychain: KeychainManager!

    override func setUp() {
        super.setUp()
        keychain = KeychainManager.shared

        // Clean up any existing test data
        try? keychain.deleteAll()
    }

    override func tearDown() {
        // Clean up test data
        try? keychain.deleteAll()
        super.tearDown()
    }

    // MARK: - Save and Retrieve Tests

    func testSaveAndRetrieveString() throws {
        let key = "test_key"
        let value = "test_value"

        // Save
        try keychain.save(key: key, value: value)

        // Retrieve
        let retrieved = try keychain.retrieve(key: key)

        XCTAssertEqual(retrieved, value)
    }

    func testSaveAndRetrieveData() throws {
        let key = "test_data_key"
        let value = "test_value"
        let data = value.data(using: .utf8)!

        // Save
        try keychain.save(key: key, data: data)

        // Retrieve
        let retrieved = try keychain.retrieveData(key: key)

        XCTAssertEqual(retrieved, data)
        XCTAssertEqual(String(data: retrieved, encoding: .utf8), value)
    }

    func testOverwriteExistingValue() throws {
        let key = "test_key"
        let value1 = "value1"
        let value2 = "value2"

        // Save first value
        try keychain.save(key: key, value: value1)

        // Overwrite with second value
        try keychain.save(key: key, value: value2)

        // Retrieve
        let retrieved = try keychain.retrieve(key: key)

        XCTAssertEqual(retrieved, value2)
    }

    // MARK: - Delete Tests

    func testDeleteValue() throws {
        let key = "test_key"
        let value = "test_value"

        // Save
        try keychain.save(key: key, value: value)

        // Verify it exists
        XCTAssertTrue(keychain.exists(key: key))

        // Delete
        try keychain.delete(key: key)

        // Verify it doesn't exist
        XCTAssertFalse(keychain.exists(key: key))
    }

    func testDeleteNonExistentValue() throws {
        let key = "nonexistent_key"

        // Should not throw error when deleting non-existent key
        XCTAssertNoThrow(try keychain.delete(key: key))
    }

    func testDeleteAll() throws {
        // Save multiple values
        try keychain.save(key: "key1", value: "value1")
        try keychain.save(key: "key2", value: "value2")
        try keychain.save(key: "key3", value: "value3")

        // Verify they exist
        XCTAssertTrue(keychain.exists(key: "key1"))
        XCTAssertTrue(keychain.exists(key: "key2"))
        XCTAssertTrue(keychain.exists(key: "key3"))

        // Delete all
        try keychain.deleteAll()

        // Verify they don't exist
        XCTAssertFalse(keychain.exists(key: "key1"))
        XCTAssertFalse(keychain.exists(key: "key2"))
        XCTAssertFalse(keychain.exists(key: "key3"))
    }

    // MARK: - Error Tests

    func testRetrieveNonExistentValue() {
        let key = "nonexistent_key"

        XCTAssertThrowsError(try keychain.retrieve(key: key)) { error in
            XCTAssertTrue(error is KeychainError)
            if case KeychainError.itemNotFound = error {
                // Expected error
            } else {
                XCTFail("Expected KeychainError.itemNotFound")
            }
        }
    }

    // MARK: - Exists Tests

    func testExistsReturnsTrueForExistingKey() throws {
        let key = "test_key"
        let value = "test_value"

        try keychain.save(key: key, value: value)

        XCTAssertTrue(keychain.exists(key: key))
    }

    func testExistsReturnsFalseForNonExistentKey() {
        let key = "nonexistent_key"

        XCTAssertFalse(keychain.exists(key: key))
    }

    // MARK: - Token Storage Tests

    func testSaveAndRetrieveTokens() throws {
        // Save tokens
        try keychain.save(key: KeychainManager.Keys.accessToken, value: "access_token_123")
        try keychain.save(key: KeychainManager.Keys.idToken, value: "id_token_456")
        try keychain.save(key: KeychainManager.Keys.refreshToken, value: "refresh_token_789")
        try keychain.save(key: KeychainManager.Keys.userEmail, value: "test@example.com")

        // Retrieve tokens
        let accessToken = try keychain.retrieve(key: KeychainManager.Keys.accessToken)
        let idToken = try keychain.retrieve(key: KeychainManager.Keys.idToken)
        let refreshToken = try keychain.retrieve(key: KeychainManager.Keys.refreshToken)
        let userEmail = try keychain.retrieve(key: KeychainManager.Keys.userEmail)

        XCTAssertEqual(accessToken, "access_token_123")
        XCTAssertEqual(idToken, "id_token_456")
        XCTAssertEqual(refreshToken, "refresh_token_789")
        XCTAssertEqual(userEmail, "test@example.com")
    }
}
