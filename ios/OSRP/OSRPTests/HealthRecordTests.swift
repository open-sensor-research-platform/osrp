//
//  HealthRecordTests.swift
//  OSRPTests
//
//  Unit tests for HealthRecord Core Data entity
//

import XCTest
import CoreData
@testable import OSRP

final class HealthRecordTests: XCTestCase {
    var persistentContainer: NSPersistentContainer!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()

        // Create in-memory persistent container for testing
        persistentContainer = NSPersistentContainer(name: "HealthData")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]

        persistentContainer.loadPersistentStores { description, error in
            XCTAssertNil(error)
        }

        context = persistentContainer.viewContext
    }

    override func tearDown() {
        context = nil
        persistentContainer = nil
        super.tearDown()
    }

    func testCreateHealthRecord() {
        let userId = "test@example.com"
        let dataType = "steps"
        let value = 10000.0
        let startDate = Date()
        let endDate = Date().addingTimeInterval(3600)

        let record = HealthRecord.create(
            in: context,
            userId: userId,
            dataType: dataType,
            value: value,
            unit: "count",
            startDate: startDate,
            endDate: endDate,
            sourceIdentifier: "HealthKit"
        )

        XCTAssertNotNil(record.id)
        XCTAssertEqual(record.userId, userId)
        XCTAssertEqual(record.dataType, dataType)
        XCTAssertEqual(record.value, value)
        XCTAssertEqual(record.unit, "count")
        XCTAssertEqual(record.startDate, startDate)
        XCTAssertEqual(record.endDate, endDate)
        XCTAssertEqual(record.sourceIdentifier, "HealthKit")
        XCTAssertEqual(record.status, .pending)
        XCTAssertEqual(record.retryCount, 0)
    }

    func testUploadStatus() {
        let record = HealthRecord.create(
            in: context,
            userId: "test@example.com",
            dataType: "steps",
            value: 5000,
            startDate: Date(),
            endDate: Date()
        )

        // Test initial status
        XCTAssertEqual(record.status, .pending)

        // Test status changes
        record.status = .uploading
        XCTAssertEqual(record.status, .uploading)
        XCTAssertEqual(record.uploadStatus, 1)

        record.status = .uploaded
        XCTAssertEqual(record.status, .uploaded)
        XCTAssertEqual(record.uploadStatus, 2)

        record.status = .failed
        XCTAssertEqual(record.status, .failed)
        XCTAssertEqual(record.uploadStatus, 3)
    }

    func testSaveContext() throws {
        HealthRecord.create(
            in: context,
            userId: "test@example.com",
            dataType: "heart_rate",
            value: 72.0,
            unit: "bpm",
            startDate: Date(),
            endDate: Date()
        )

        XCTAssertTrue(context.hasChanges)

        try context.save()

        XCTAssertFalse(context.hasChanges)
    }

    func testFetchHealthRecords() throws {
        // Create multiple records
        for i in 0..<5 {
            HealthRecord.create(
                in: context,
                userId: "test@example.com",
                dataType: "steps",
                value: Double(1000 * i),
                startDate: Date().addingTimeInterval(TimeInterval(i * 3600)),
                endDate: Date().addingTimeInterval(TimeInterval((i + 1) * 3600))
            )
        }

        try context.save()

        // Fetch records
        let fetchRequest: NSFetchRequest<HealthRecord> = HealthRecord.fetchRequest()
        let records = try context.fetch(fetchRequest)

        XCTAssertEqual(records.count, 5)
    }

    func testFetchPendingRecords() throws {
        // Create records with different statuses
        let record1 = HealthRecord.create(
            in: context,
            userId: "test@example.com",
            dataType: "steps",
            value: 1000,
            startDate: Date(),
            endDate: Date()
        )
        record1.status = .pending

        let record2 = HealthRecord.create(
            in: context,
            userId: "test@example.com",
            dataType: "steps",
            value: 2000,
            startDate: Date(),
            endDate: Date()
        )
        record2.status = .uploaded

        let record3 = HealthRecord.create(
            in: context,
            userId: "test@example.com",
            dataType: "steps",
            value: 3000,
            startDate: Date(),
            endDate: Date()
        )
        record3.status = .pending

        try context.save()

        // Fetch only pending records
        let fetchRequest: NSFetchRequest<HealthRecord> = HealthRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uploadStatus == %d", HealthRecord.UploadStatus.pending.rawValue)

        let pendingRecords = try context.fetch(fetchRequest)

        XCTAssertEqual(pendingRecords.count, 2)
        XCTAssertTrue(pendingRecords.allSatisfy { $0.status == .pending })
    }
}
