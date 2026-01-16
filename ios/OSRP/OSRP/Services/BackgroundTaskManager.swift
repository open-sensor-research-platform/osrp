//
//  BackgroundTaskManager.swift
//  OSRP
//
//  Manages background upload tasks
//  Uses BGTaskScheduler for periodic background uploads
//

import Foundation
import BackgroundTasks

@MainActor
class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    /// Task identifier for background upload
    private let uploadTaskIdentifier = "io.osrp.app.upload"

    /// Upload service
    private let uploadService = UploadService()

    private init() {}

    // MARK: - Registration

    /// Register background tasks
    /// Must be called in application:didFinishLaunchingWithOptions:
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: uploadTaskIdentifier,
            using: nil
        ) { task in
            self.handleUploadTask(task: task as! BGAppRefreshTask)
        }

        print("Background tasks registered")
    }

    // MARK: - Scheduling

    /// Schedule background upload task
    func scheduleUploadTask() {
        let request = BGAppRefreshTaskRequest(identifier: uploadTaskIdentifier)

        // Schedule for 1 hour from now
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background upload task scheduled")
        } catch {
            print("Failed to schedule background upload: \(error.localizedDescription)")
        }
    }

    /// Cancel scheduled upload task
    func cancelUploadTask() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: uploadTaskIdentifier)
        print("Background upload task cancelled")
    }

    // MARK: - Task Handling

    /// Handle background upload task
    private func handleUploadTask(task: BGAppRefreshTask) {
        print("Background upload task started")

        // Schedule next task
        scheduleUploadTask()

        // Create upload task
        let uploadTask = Task {
            await uploadService.uploadNow()
        }

        // Set expiration handler
        task.expirationHandler = {
            print("Background task expired")
            uploadTask.cancel()
        }

        // Wait for upload to complete
        Task {
            _ = await uploadTask.value
            task.setTaskCompleted(success: true)
            print("Background upload task completed")
        }
    }

    // MARK: - Testing

    /// Simulate background task (for testing in simulator)
    func simulateBackgroundTask() {
        #if DEBUG
        Task {
            print("Simulating background upload task...")
            await uploadService.uploadNow()
            print("Simulated background upload completed")
        }
        #endif
    }
}
