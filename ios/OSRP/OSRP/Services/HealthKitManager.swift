//
//  HealthKitManager.swift
//  OSRP
//
//  HealthKit manager for requesting permissions and reading health data
//

import Foundation
import HealthKit

enum HealthKitError: Error {
    case notAvailable
    case authorizationDenied
    case noData
    case queryFailed(Error)
}

class HealthKitManager {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    private init() {}

    // MARK: - Availability

    /// Check if HealthKit is available on this device
    func isHealthKitAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    /// Request HealthKit authorization for reading step count data
    func requestAuthorization() async throws {
        guard isHealthKitAvailable() else {
            throw HealthKitError.notAvailable
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        } catch {
            throw HealthKitError.authorizationDenied
        }
    }

    /// Check authorization status for step count
    func authorizationStatus() -> HKAuthorizationStatus {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return .notDetermined
        }
        return healthStore.authorizationStatus(for: stepCountType)
    }

    // MARK: - Query Step Count

    /// Query step count for a specific date range
    func queryStepCount(startDate: Date, endDate: Date) async throws -> [(date: Date, steps: Double)] {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.notAvailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startOfDay(for: startDate),
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { query, results, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                guard let results = results else {
                    continuation.resume(throwing: HealthKitError.noData)
                    return
                }

                var stepData: [(date: Date, steps: Double)] = []

                results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        let steps = sum.doubleValue(for: HKUnit.count())
                        stepData.append((date: statistics.startDate, steps: steps))
                    }
                }

                continuation.resume(returning: stepData)
            }

            healthStore.execute(query)
        }
    }

    /// Query step count for today
    func queryTodayStepCount() async throws -> Double {
        let now = Date()
        let startOfToday = startOfDay(for: now)

        let stepData = try await queryStepCount(startDate: startOfToday, endDate: now)

        guard let todaySteps = stepData.first else {
            return 0
        }

        return todaySteps.steps
    }

    /// Query step count for last N days
    func queryStepCountForLastDays(_ days: Int) async throws -> [(date: Date, steps: Double)] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!

        return try await queryStepCount(startDate: startDate, endDate: endDate)
    }

    // MARK: - Query Heart Rate

    /// Query heart rate samples for a date range
    func queryHeartRate(startDate: Date, endDate: Date) async throws -> [(date: Date, bpm: Double)] {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.notAvailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let heartRateData = samples.map { sample in
                    let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    return (date: sample.startDate, bpm: bpm)
                }

                continuation.resume(returning: heartRateData)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Query Activity Energy

    /// Query active energy burned for a date range
    func queryActiveEnergy(startDate: Date, endDate: Date) async throws -> [(date: Date, calories: Double)] {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.notAvailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startOfDay(for: startDate),
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { query, results, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                guard let results = results else {
                    continuation.resume(throwing: HealthKitError.noData)
                    return
                }

                var energyData: [(date: Date, calories: Double)] = []

                results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                        energyData.append((date: statistics.startDate, calories: calories))
                    }
                }

                continuation.resume(returning: energyData)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Observer Query

    /// Enable background delivery for step count updates
    func enableBackgroundDelivery(for identifier: HKQuantityTypeIdentifier, frequency: HKUpdateFrequency = .daily) async throws {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            throw HealthKitError.notAvailable
        }

        try await healthStore.enableBackgroundDelivery(for: quantityType, frequency: frequency)
    }

    /// Disable background delivery
    func disableBackgroundDelivery(for identifier: HKQuantityTypeIdentifier) async throws {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            throw HealthKitError.notAvailable
        }

        try await healthStore.disableBackgroundDelivery(for: quantityType)
    }

    // MARK: - Helper Methods

    private func startOfDay(for date: Date) -> Date {
        return Calendar.current.startOfDay(for: date)
    }
}
