//
//  DataService.swift
//  OSRP
//
//  Data collection service
//  Manages HealthKit data collection and storage
//

import Foundation

actor DataService {
    private let healthKitService = HealthKitService()
    private let coreDataManager = CoreDataManager.shared
    private let authService = AuthService()

    /// Check if data collection is running
    func isCollecting() async -> Bool {
        return await healthKitService.isCurrentlyCollecting()
    }

    /// Request HealthKit permissions
    func requestHealthKitPermissions() async throws {
        try await healthKitService.requestAuthorization()
    }

    /// Check if HealthKit is authorized
    func isHealthKitAuthorized() async -> Bool {
        return await healthKitService.isAuthorized()
    }

    /// Start data collection
    func startCollection() async {
        // Get user ID from auth service
        guard let email = await authService.getUserEmail() else {
            print("No user logged in, cannot start collection")
            return
        }

        // Start HealthKit collection
        await healthKitService.startCollection(userId: email)

        print("Started HealthKit data collection for user: \(email)")
    }

    /// Stop data collection
    func stopCollection() async {
        await healthKitService.stopCollection()
        print("Stopped HealthKit data collection")
    }

    /// Manually trigger data collection
    func collectNow() async {
        guard let email = await authService.getUserEmail() else {
            print("No user logged in, cannot collect data")
            return
        }

        await healthKitService.collectNow(userId: email)
        print("Triggered manual data collection")
    }

    /// Get count of pending records
    func getPendingRecordsCount() async -> Int {
        return coreDataManager.countPendingRecords()
    }

    /// Get pending records for upload
    func getPendingRecords() async -> [HealthRecord] {
        return coreDataManager.fetchPendingRecords()
    }

    /// Update upload status for records
    func updateUploadStatus(
        records: [HealthRecord],
        status: HealthRecord.UploadStatus,
        errorMessage: String? = nil
    ) async {
        coreDataManager.updateUploadStatus(
            records: records,
            status: status,
            errorMessage: errorMessage
        )
    }
}
