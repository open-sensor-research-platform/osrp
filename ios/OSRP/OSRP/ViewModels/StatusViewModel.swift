//
//  StatusViewModel.swift
//  OSRP
//
//  Status dashboard view model
//  Manages real-time status updates for data collection and uploads
//

import Foundation
import Combine

@MainActor
class StatusViewModel: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var isCollecting: Bool = false
    @Published var isUploadRunning: Bool = false
    @Published var pendingRecords: Int = 0

    private let dataService = DataService()
    private let uploadService = UploadService()
    private var refreshTask: Task<Void, Never>?

    init() {
        Task {
            await refreshStatus()
        }
    }

    deinit {
        refreshTask?.cancel()
    }

    /// Start periodic status refresh (every 5 seconds)
    func startPeriodicRefresh() {
        refreshTask?.cancel()

        refreshTask = Task {
            while !Task.isCancelled {
                await refreshStatus()
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            }
        }
    }

    /// Stop periodic refresh
    func stopPeriodicRefresh() {
        refreshTask?.cancel()
    }

    /// Refresh all status information
    func refreshStatus() async {
        // Check connection status
        isConnected = await checkConnectionStatus()

        // Check collection status
        isCollecting = await dataService.isCollecting()

        // Check upload status
        isUploadRunning = await uploadService.isUploadRunning()

        // Get pending records count
        pendingRecords = await dataService.getPendingRecordsCount()
    }

    /// Start data collection
    func startCollection() {
        Task {
            await dataService.startCollection()
            isCollecting = true
        }
    }

    /// Stop data collection
    func stopCollection() {
        Task {
            await dataService.stopCollection()
            isCollecting = false
        }
    }

    /// Upload now
    func uploadNow() {
        Task {
            await uploadService.uploadNow()
        }
    }

    /// Check connection status
    private func checkConnectionStatus() async -> Bool {
        // Check if we have valid auth token
        // In real implementation, this would check with AuthService
        return true
    }
}
