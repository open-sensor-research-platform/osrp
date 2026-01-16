//
//  CoreDataManagerTests.swift
//  OSRPTests
//
//  Unit tests for CoreDataManager
//

import XCTest
import CoreData
@testable import OSRP

final class CoreDataManagerTests: XCTestCase {
    var coreDataManager: CoreDataManager!

    override func setUp() {
        super.setUp()
        coreDataManager = CoreDataManager.shared

        // Clean up any existing data
        let records = coreDataManager.fetchPendingRecords()
        for record in records {
            coreDataManager.viewContext.delete(record)
        }
        coreDataManager.saveContext()
    }

    override func tearDown() {
        // Clean up test data
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = HealthRecord.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try coreDataManager.viewContext.execute(deleteRequest)
            coreDataManager.saveContext()
        } catch {
            print("Error cleaning up test data: \(error)")
        }

        coreDataManager = nil
        super.tearDown()
    }

    func testSaveContext() {
        HealthRecord.create(
            in: coreDataManager.viewContext,
            userId: "test@example.com",
            dataType: "steps",
            value: 5000,
            startDate: Date(),
            endDate: Date()
        )

        XCTAssertTrue(coreDataManager.viewContext.hasChanges)

        coreDataManager.saveContext()

        XCTAssertFalse(coreDataManager.viewContext.hasChanges)
    }

    func testFetchPendingRecords() {
        // Create pending and uploaded records
        let pending1 = HealthRecord.create(
            in: coreDataManager.viewContext,
            userId: "test@example.com",
            dataType: "steps",
            value: 1000,
            startDate: Date(),
            endDate: Date()
        )
        pending1.status = .pending

        let uploaded = HealthRecord.create(
            in: coreDataManager.viewContext,
            userId: "test@example.com",
            dataType: "steps",
            value: 2000,
            startDate: Date(),
            endDate: Date()
        )
        uploaded.status = .uploaded

        let pending2 = HealthRecord.create(
            in: coreDataManager.viewContext,
            userId: "test@example.com",
            dataType: "steps",
            value: 3000,
            startDate: Date(),
            endDate: Date()
        )
        pending2.status = .pending

        coreDataManager.saveContext()

        let pendingRecords = coreDataManager.fetchPendingRecords()

        XCTAssertEqual(pendingRecords.count, 2)
        XCTAssertTrue(pendingRecords.allSatisfy { $0.status == .pending })
    }

    func testCountPendingRecords() {
        // Create records
        for i in 0..<5 {
            let record = HealthRecord.create(
                in: coreDataManager.viewContext,
                userId: "test@example.com",
                dataType: "steps",
                value: Double(i * 1000),
                startDate: Date(),
                endDate: Date()
            )
            record.status = i < 3 ? .pending : .uploaded
        }

        coreDataManager.saveContext()

        let count = coreDataManager.countPendingRecords()

        XCTAssertEqual(count, 3)
    }

    func testFetchRecordsByStatus() {
        // Create records with different statuses
        let statuses: [HealthRecord.UploadStatus] = [.pending, .uploading, .uploaded, .failed, .pending]

        for status in statuses {
            let record = HealthRecord.create(
                in: coreDataManager.viewContext,
                userId: "test@example.com",
                dataType: "steps",
                value: 1000,
                startDate: Date(),
                endDate: Date()
            )
            record.status = status
        }

        coreDataManager.saveContext()

        let pendingRecords = coreDataManager.fetchRecords(status: .pending)
        XCTAssertEqual(pendingRecords.count, 2)

        let uploadedRecords = coreDataManager.fetchRecords(status: .uploaded)
        XCTAssertEqual(uploadedRecords.count, 1)

        let uploadingRecords = coreDataManager.fetchRecords(status: .uploading)
        XCTAssertEqual(uploadingRecords.count, 1)

        let failedRecords = coreDataManager.fetchRecords(status: .failed)
        XCTAssertEqual(failedRecords.count, 1)
    }

    func testUpdateUploadStatus() {
        let record1 = HealthRecord.create(
            in: coreDataManager.viewContext,
            userId: "test@example.com",
            dataType: "steps",
            value: 1000,
            startDate: Date(),
            endDate: Date()
        )

        let record2 = HealthRecord.create(
            in: coreDataManager.viewContext,
            userId: "test@example.com",
            dataType: "steps",
            value: 2000,
            startDate: Date(),
            endDate: Date()
        )

        coreDataManager.saveContext()

        // Update status
        coreDataManager.updateUploadStatus(
            records: [record1, record2],
            status: .uploaded
        )

        XCTAssertEqual(record1.status, .uploaded)
        XCTAssertEqual(record2.status, .uploaded)
    }

    func testUpdateUploadStatusWithError() {
        let record = HealthRecord.create(
            in: coreDataManager.viewContext,
            userId: "test@example.com",
            dataType: "steps",
            value: 1000,
            startDate: Date(),
            endDate: Date()
        )

        coreDataManager.saveContext()

        let initialRetryCount = record.retryCount

        // Update status with error
        coreDataManager.updateUploadStatus(
            records: [record],
            status: .failed,
            errorMessage: "Network error"
        )

        XCTAssertEqual(record.status, .failed)
        XCTAssertEqual(record.errorMessage, "Network error")
        XCTAssertEqual(record.retryCount, initialRetryCount + 1)
    }
}
