//
//  HealthRecord.swift
//  OSRP
//
//  Core Data entity for health records
//

import Foundation
import CoreData

@objc(HealthRecord)
public class HealthRecord: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var userId: String
    @NSManaged public var dataType: String
    @NSManaged public var value: Double
    @NSManaged public var unit: String?
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var sourceIdentifier: String?
    @NSManaged public var metadata: String?
    @NSManaged public var uploadStatus: Int16
    @NSManaged public var retryCount: Int16
    @NSManaged public var errorMessage: String?
    @NSManaged public var createdAt: Date
}

// MARK: - Upload Status

extension HealthRecord {
    enum UploadStatus: Int16 {
        case pending = 0
        case uploading = 1
        case uploaded = 2
        case failed = 3
    }

    var status: UploadStatus {
        get { UploadStatus(rawValue: uploadStatus) ?? .pending }
        set { uploadStatus = newValue.rawValue }
    }
}

// MARK: - Factory Methods

extension HealthRecord {
    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        userId: String,
        dataType: String,
        value: Double,
        unit: String? = nil,
        startDate: Date,
        endDate: Date,
        sourceIdentifier: String? = nil,
        metadata: String? = nil
    ) -> HealthRecord {
        let record = HealthRecord(context: context)
        record.id = UUID()
        record.userId = userId
        record.dataType = dataType
        record.value = value
        record.unit = unit
        record.startDate = startDate
        record.endDate = endDate
        record.sourceIdentifier = sourceIdentifier
        record.metadata = metadata
        record.uploadStatus = UploadStatus.pending.rawValue
        record.retryCount = 0
        record.createdAt = Date()
        return record
    }
}
