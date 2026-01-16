//
//  PreferencesManager.swift
//  OSRP
//
//  UserDefaults wrapper for app preferences
//

import Foundation

class PreferencesManager {
    static let shared = PreferencesManager()

    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Keys

    private enum Keys {
        static let autoUploadEnabled = "autoUploadEnabled"
        static let uploadWiFiOnly = "uploadWiFiOnly"
        static let uploadIntervalMinutes = "uploadIntervalMinutes"
        static let lastUploadTime = "lastUploadTime"
        static let dataCollectionEnabled = "dataCollectionEnabled"
    }

    // MARK: - Upload Settings

    var autoUploadEnabled: Bool {
        get { defaults.bool(forKey: Keys.autoUploadEnabled) }
        set { defaults.set(newValue, forKey: Keys.autoUploadEnabled) }
    }

    var uploadWiFiOnly: Bool {
        get { defaults.object(forKey: Keys.uploadWiFiOnly) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.uploadWiFiOnly) }
    }

    var uploadIntervalMinutes: Int {
        get { defaults.object(forKey: Keys.uploadIntervalMinutes) as? Int ?? 60 }
        set { defaults.set(newValue, forKey: Keys.uploadIntervalMinutes) }
    }

    var lastUploadTime: Date? {
        get { defaults.object(forKey: Keys.lastUploadTime) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastUploadTime) }
    }

    // MARK: - Collection Settings

    var dataCollectionEnabled: Bool {
        get { defaults.bool(forKey: Keys.dataCollectionEnabled) }
        set { defaults.set(newValue, forKey: Keys.dataCollectionEnabled) }
    }

    // MARK: - Reset

    func resetToDefaults() {
        defaults.removeObject(forKey: Keys.autoUploadEnabled)
        defaults.removeObject(forKey: Keys.uploadWiFiOnly)
        defaults.removeObject(forKey: Keys.uploadIntervalMinutes)
        defaults.removeObject(forKey: Keys.lastUploadTime)
        defaults.removeObject(forKey: Keys.dataCollectionEnabled)
    }
}
