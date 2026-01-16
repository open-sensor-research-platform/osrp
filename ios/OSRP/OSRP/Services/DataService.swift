//
//  DataService.swift
//  OSRP
//
//  Data collection service
//  Manages HealthKit data collection
//

import Foundation

actor DataService {
    private var collecting: Bool = false

    /// Check if data collection is running
    func isCollecting() async -> Bool {
        return collecting
    }

    /// Start data collection
    func startCollection() async {
        // TODO: Implement HealthKit data collection in Issue #19
        collecting = true
        print("Starting data collection...")
    }

    /// Stop data collection
    func stopCollection() async {
        // TODO: Implement stopping collection in Issue #19
        collecting = false
        print("Stopping data collection...")
    }

    /// Get count of pending records
    func getPendingRecordsCount() async -> Int {
        // TODO: Implement actual count from Core Data in Issue #19
        return 0
    }
}
