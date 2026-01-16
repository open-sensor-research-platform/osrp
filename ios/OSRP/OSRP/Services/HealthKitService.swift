//
//  HealthKitService.swift
//  OSRP
//
//  Service for coordinating HealthKit data collection and storage
//

import Foundation
import HealthKit

actor HealthKitService {
    private let healthKitManager = HealthKitManager.shared
    private let coreDataManager = CoreDataManager.shared
    private var isCollecting = false
    private var collectionTask: Task<Void, Never>?

    /// Request HealthKit authorization
    func requestAuthorization() async throws {
        try await healthKitManager.requestAuthorization()
    }

    /// Check if HealthKit is authorized
    func isAuthorized() -> Bool {
        let status = healthKitManager.authorizationStatus()
        return status == .sharingAuthorized
    }

    /// Start collecting health data
    func startCollection(userId: String) async {
        guard !isCollecting else { return }
        isCollecting = true

        // Enable background delivery for step count
        try? await healthKitManager.enableBackgroundDelivery(
            for: .stepCount,
            frequency: .daily
        )

        // Start periodic collection task
        collectionTask = Task {
            while !Task.isCancelled && isCollecting {
                await collectHealthData(userId: userId)

                // Wait 1 hour before next collection
                try? await Task.sleep(nanoseconds: 3_600_000_000_000) // 1 hour
            }
        }
    }

    /// Stop collecting health data
    func stopCollection() async {
        isCollecting = false
        collectionTask?.cancel()
        collectionTask = nil

        // Disable background delivery
        try? await healthKitManager.disableBackgroundDelivery(for: .stepCount)
    }

    /// Check if currently collecting
    func isCurrentlyCollecting() -> Bool {
        return isCollecting
    }

    /// Manually trigger data collection
    func collectNow(userId: String) async {
        await collectHealthData(userId: userId)
    }

    // MARK: - Private Methods

    /// Collect health data and save to Core Data
    private func collectHealthData(userId: String) async {
        // Collect last 7 days of data
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!

        // Collect step count
        await collectStepCount(userId: userId, startDate: startDate, endDate: endDate)

        // Collect heart rate
        await collectHeartRate(userId: userId, startDate: startDate, endDate: endDate)

        // Collect active energy
        await collectActiveEnergy(userId: userId, startDate: startDate, endDate: endDate)

        // Clean up old uploaded records (older than 30 days)
        coreDataManager.deleteOldUploadedRecords(olderThanDays: 30)
    }

    /// Collect step count data
    private func collectStepCount(userId: String, startDate: Date, endDate: Date) async {
        do {
            let stepData = try await healthKitManager.queryStepCount(startDate: startDate, endDate: endDate)

            for (date, steps) in stepData {
                // Check if record already exists for this date
                if !recordExists(userId: userId, dataType: "steps", date: date) {
                    HealthRecord.create(
                        in: coreDataManager.viewContext,
                        userId: userId,
                        dataType: "steps",
                        value: steps,
                        unit: "count",
                        startDate: date,
                        endDate: Calendar.current.date(byAdding: .day, value: 1, to: date)!,
                        sourceIdentifier: "HealthKit"
                    )
                }
            }

            coreDataManager.saveContext()

        } catch {
            print("Error collecting step count: \(error)")
        }
    }

    /// Collect heart rate data
    private func collectHeartRate(userId: String, startDate: Date, endDate: Date) async {
        do {
            let heartRateData = try await healthKitManager.queryHeartRate(startDate: startDate, endDate: endDate)

            for (date, bpm) in heartRateData {
                // Check if record already exists
                if !recordExists(userId: userId, dataType: "heart_rate", date: date) {
                    HealthRecord.create(
                        in: coreDataManager.viewContext,
                        userId: userId,
                        dataType: "heart_rate",
                        value: bpm,
                        unit: "bpm",
                        startDate: date,
                        endDate: date,
                        sourceIdentifier: "HealthKit"
                    )
                }
            }

            coreDataManager.saveContext()

        } catch {
            print("Error collecting heart rate: \(error)")
        }
    }

    /// Collect active energy data
    private func collectActiveEnergy(userId: String, startDate: Date, endDate: Date) async {
        do {
            let energyData = try await healthKitManager.queryActiveEnergy(startDate: startDate, endDate: endDate)

            for (date, calories) in energyData {
                // Check if record already exists
                if !recordExists(userId: userId, dataType: "active_energy", date: date) {
                    HealthRecord.create(
                        in: coreDataManager.viewContext,
                        userId: userId,
                        dataType: "active_energy",
                        value: calories,
                        unit: "kcal",
                        startDate: date,
                        endDate: Calendar.current.date(byAdding: .day, value: 1, to: date)!,
                        sourceIdentifier: "HealthKit"
                    )
                }
            }

            coreDataManager.saveContext()

        } catch {
            print("Error collecting active energy: \(error)")
        }
    }

    /// Check if a record already exists
    private func recordExists(userId: String, dataType: String, date: Date) -> Bool {
        let fetchRequest = HealthRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "userId == %@ AND dataType == %@ AND startDate == %@",
            userId,
            dataType,
            date as NSDate
        )
        fetchRequest.fetchLimit = 1

        do {
            let count = try coreDataManager.viewContext.count(for: fetchRequest)
            return count > 0
        } catch {
            return false
        }
    }
}
