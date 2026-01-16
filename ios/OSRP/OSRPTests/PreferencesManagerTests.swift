//
//  PreferencesManagerTests.swift
//  OSRPTests
//
//  Unit tests for PreferencesManager
//

import XCTest
@testable import OSRP

final class PreferencesManagerTests: XCTestCase {
    var preferences: PreferencesManager!

    override func setUp() {
        super.setUp()
        preferences = PreferencesManager.shared
        preferences.resetToDefaults()
    }

    override func tearDown() {
        preferences.resetToDefaults()
        preferences = nil
        super.tearDown()
    }

    func testDefaultValues() {
        // Auto upload should be false by default
        XCTAssertFalse(preferences.autoUploadEnabled)

        // WiFi-only should be true by default
        XCTAssertTrue(preferences.uploadWiFiOnly)

        // Upload interval should be 60 minutes by default
        XCTAssertEqual(preferences.uploadIntervalMinutes, 60)

        // Last upload time should be nil by default
        XCTAssertNil(preferences.lastUploadTime)

        // Data collection should be false by default
        XCTAssertFalse(preferences.dataCollectionEnabled)
    }

    func testSetAutoUploadEnabled() {
        preferences.autoUploadEnabled = true
        XCTAssertTrue(preferences.autoUploadEnabled)

        preferences.autoUploadEnabled = false
        XCTAssertFalse(preferences.autoUploadEnabled)
    }

    func testSetUploadWiFiOnly() {
        preferences.uploadWiFiOnly = false
        XCTAssertFalse(preferences.uploadWiFiOnly)

        preferences.uploadWiFiOnly = true
        XCTAssertTrue(preferences.uploadWiFiOnly)
    }

    func testSetUploadIntervalMinutes() {
        preferences.uploadIntervalMinutes = 30
        XCTAssertEqual(preferences.uploadIntervalMinutes, 30)

        preferences.uploadIntervalMinutes = 120
        XCTAssertEqual(preferences.uploadIntervalMinutes, 120)
    }

    func testSetLastUploadTime() {
        let now = Date()
        preferences.lastUploadTime = now

        XCTAssertNotNil(preferences.lastUploadTime)
        XCTAssertEqual(
            preferences.lastUploadTime?.timeIntervalSince1970,
            now.timeIntervalSince1970,
            accuracy: 1.0
        )
    }

    func testSetDataCollectionEnabled() {
        preferences.dataCollectionEnabled = true
        XCTAssertTrue(preferences.dataCollectionEnabled)

        preferences.dataCollectionEnabled = false
        XCTAssertFalse(preferences.dataCollectionEnabled)
    }

    func testResetToDefaults() {
        // Set some values
        preferences.autoUploadEnabled = true
        preferences.uploadWiFiOnly = false
        preferences.uploadIntervalMinutes = 30
        preferences.lastUploadTime = Date()
        preferences.dataCollectionEnabled = true

        // Reset
        preferences.resetToDefaults()

        // Verify defaults
        XCTAssertFalse(preferences.autoUploadEnabled)
        XCTAssertTrue(preferences.uploadWiFiOnly)
        XCTAssertEqual(preferences.uploadIntervalMinutes, 60)
        XCTAssertNil(preferences.lastUploadTime)
        XCTAssertFalse(preferences.dataCollectionEnabled)
    }

    func testPersistence() {
        // Set values
        preferences.autoUploadEnabled = true
        preferences.uploadIntervalMinutes = 45

        // Create new instance (simulating app restart)
        let newPreferences = PreferencesManager.shared

        // Verify values persisted
        XCTAssertTrue(newPreferences.autoUploadEnabled)
        XCTAssertEqual(newPreferences.uploadIntervalMinutes, 45)
    }
}
