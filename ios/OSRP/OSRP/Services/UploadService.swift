//
//  UploadService.swift
//  OSRP
//
//  Data upload service
//  Handles uploading health data to AWS with retry logic
//

import Foundation
import Network

actor UploadService {
    private var uploadRunning: Bool = false
    private let coreDataManager = CoreDataManager.shared
    private let authService = AuthService()
    private let preferences = PreferencesManager.shared
    private let baseURL: String
    private let session: URLSession
    private let networkMonitor = NWPathMonitor()

    /// Maximum records to upload per batch
    private let batchSize = 100

    /// Maximum retry attempts
    private let maxRetries = 3

    /// Initial retry delay (doubles each retry)
    private let initialRetryDelay: TimeInterval = 2.0

    init(baseURL: String = Config.apiBaseURL) {
        self.baseURL = baseURL

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Config.requestTimeout
        configuration.timeoutIntervalForResource = Config.requestTimeout
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration)

        // Start network monitoring
        networkMonitor.start(queue: DispatchQueue.global())
    }

    // MARK: - Public Methods

    /// Check if upload is currently running
    func isUploadRunning() async -> Bool {
        return uploadRunning
    }

    /// Upload data now
    func uploadNow() async {
        guard !uploadRunning else {
            print("Upload already in progress")
            return
        }

        uploadRunning = true
        defer { uploadRunning = false }

        print("Starting upload...")

        // Check network connectivity
        guard await isNetworkAvailable() else {
            print("No network connection available")
            return
        }

        // Check WiFi-only setting
        if preferences.uploadWiFiOnly && !await isOnWiFi() {
            print("WiFi-only enabled but not on WiFi, skipping upload")
            return
        }

        // Get authorization header
        guard let authHeader = await authService.getAuthorizationHeader() else {
            print("Not authenticated, cannot upload")
            return
        }

        // Get pending records
        let pendingRecords = coreDataManager.fetchPendingRecords()

        guard !pendingRecords.isEmpty else {
            print("No pending records to upload")
            preferences.lastUploadTime = Date()
            return
        }

        print("Found \(pendingRecords.count) pending records")

        // Upload in batches
        var successCount = 0
        var failCount = 0

        for batchStart in stride(from: 0, to: pendingRecords.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, pendingRecords.count)
            let batch = Array(pendingRecords[batchStart..<batchEnd])

            do {
                try await uploadBatch(batch, authHeader: authHeader)
                successCount += batch.count
                print("Uploaded batch of \(batch.count) records")
            } catch {
                print("Failed to upload batch: \(error.localizedDescription)")
                failCount += batch.count
            }
        }

        print("Upload completed: \(successCount) succeeded, \(failCount) failed")
        preferences.lastUploadTime = Date()
    }

    // MARK: - Private Methods

    /// Upload a batch of records
    private func uploadBatch(_ records: [HealthRecord], authHeader: String) async throws {
        // Group records by data type
        let groupedRecords = Dictionary(grouping: records, by: { $0.dataType })

        for (dataType, typeRecords) in groupedRecords {
            // Convert to API model
            let readings = typeRecords.map { record in
                HealthReading(
                    timestamp: Int64(record.startDate.timeIntervalSince1970 * 1000), // milliseconds
                    value: record.value,
                    unit: record.unit,
                    metadata: parseMetadata(record.metadata)
                )
            }

            let request = HealthDataUploadRequest(
                dataType: dataType,
                readings: readings,
                studyCode: nil // Optional: add study code if needed
            )

            // Upload with retry
            try await uploadWithRetry(request: request, authHeader: authHeader, records: typeRecords)
        }
    }

    /// Upload with exponential backoff retry
    private func uploadWithRetry(
        request: HealthDataUploadRequest,
        authHeader: String,
        records: [HealthRecord]
    ) async throws {
        var lastError: Error?
        var retryDelay = initialRetryDelay

        for attempt in 0..<maxRetries {
            do {
                // Mark as uploading
                coreDataManager.updateUploadStatus(
                    records: records,
                    status: .uploading
                )

                // Perform upload
                try await performUpload(request: request, authHeader: authHeader)

                // Mark as uploaded
                coreDataManager.updateUploadStatus(
                    records: records,
                    status: .uploaded
                )

                return // Success!

            } catch {
                lastError = error
                print("Upload attempt \(attempt + 1) failed: \(error.localizedDescription)")

                if attempt < maxRetries - 1 {
                    // Wait before retry (exponential backoff)
                    print("Retrying in \(retryDelay) seconds...")
                    try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                    retryDelay *= 2
                }
            }
        }

        // All retries failed
        coreDataManager.updateUploadStatus(
            records: records,
            status: .failed,
            errorMessage: lastError?.localizedDescription ?? "Unknown error"
        )

        throw lastError ?? UploadError(message: "Upload failed after \(maxRetries) attempts", statusCode: nil)
    }

    /// Perform the actual HTTP upload
    private func performUpload(request: HealthDataUploadRequest, authHeader: String) async throws {
        guard let url = URL(string: "\(baseURL)data/health") else {
            throw UploadError(message: "Invalid URL", statusCode: nil)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")

        // Encode request body
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw UploadError(message: "Failed to encode request: \(error.localizedDescription)", statusCode: nil)
        }

        // Perform request
        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw UploadError(message: "Invalid response", statusCode: nil)
            }

            // Check status code
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to parse error response
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw UploadError(message: errorResponse.message, statusCode: httpResponse.statusCode)
                }
                throw UploadError(
                    message: "Upload failed with status \(httpResponse.statusCode)",
                    statusCode: httpResponse.statusCode
                )
            }

            // Parse success response
            _ = try JSONDecoder().decode(HealthDataUploadResponse.self, from: data)

        } catch let error as UploadError {
            throw error
        } catch {
            throw UploadError(message: "Network error: \(error.localizedDescription)", statusCode: nil)
        }
    }

    /// Check if network is available
    private func isNetworkAvailable() async -> Bool {
        return await withCheckedContinuation { continuation in
            let path = networkMonitor.currentPath
            continuation.resume(returning: path.status == .satisfied)
        }
    }

    /// Check if connected to WiFi
    private func isOnWiFi() async -> Bool {
        return await withCheckedContinuation { continuation in
            let path = networkMonitor.currentPath
            continuation.resume(returning: path.usesInterfaceType(.wifi))
        }
    }

    /// Parse metadata JSON string
    private func parseMetadata(_ metadataString: String?) -> [String: String]? {
        guard let metadataString = metadataString,
              let data = metadataString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return nil
        }
        return dict
    }
}
