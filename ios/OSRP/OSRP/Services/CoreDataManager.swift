//
//  CoreDataManager.swift
//  OSRP
//
//  Core Data stack manager
//

import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()

    private init() {}

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "HealthData")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Save Context

    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Error saving context: \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // MARK: - Background Context

    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }

    // MARK: - Fetch Requests

    /// Fetch all pending health records
    func fetchPendingRecords() -> [HealthRecord] {
        let fetchRequest: NSFetchRequest<HealthRecord> = HealthRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uploadStatus == %d", HealthRecord.UploadStatus.pending.rawValue)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]

        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching pending records: \(error)")
            return []
        }
    }

    /// Fetch records by upload status
    func fetchRecords(status: HealthRecord.UploadStatus) -> [HealthRecord] {
        let fetchRequest: NSFetchRequest<HealthRecord> = HealthRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uploadStatus == %d", status.rawValue)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]

        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching records: \(error)")
            return []
        }
    }

    /// Count pending records
    func countPendingRecords() -> Int {
        let fetchRequest: NSFetchRequest<HealthRecord> = HealthRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uploadStatus == %d", HealthRecord.UploadStatus.pending.rawValue)

        do {
            return try viewContext.count(for: fetchRequest)
        } catch {
            print("Error counting pending records: \(error)")
            return 0
        }
    }

    /// Delete uploaded records older than specified days
    func deleteOldUploadedRecords(olderThanDays days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = HealthRecord.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "uploadStatus == %d AND createdAt < %@",
            HealthRecord.UploadStatus.uploaded.rawValue,
            cutoffDate as NSDate
        )

        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try viewContext.execute(batchDeleteRequest)
            saveContext()
        } catch {
            print("Error deleting old records: \(error)")
        }
    }

    /// Update upload status for records
    func updateUploadStatus(records: [HealthRecord], status: HealthRecord.UploadStatus, errorMessage: String? = nil) {
        for record in records {
            record.uploadStatus = status.rawValue
            if let error = errorMessage {
                record.errorMessage = error
                record.retryCount += 1
            }
        }
        saveContext()
    }
}

// MARK: - NSFetchRequest Extension

extension HealthRecord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<HealthRecord> {
        return NSFetchRequest<HealthRecord>(entityName: "HealthRecord")
    }
}
