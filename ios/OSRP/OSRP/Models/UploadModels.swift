//
//  UploadModels.swift
//  OSRP
//
//  API models for uploading health data
//

import Foundation

// MARK: - Health Data Upload

struct HealthDataUploadRequest: Codable {
    let dataType: String
    let readings: [HealthReading]
    let studyCode: String?
}

struct HealthReading: Codable {
    let timestamp: Int64
    let value: Double
    let unit: String?
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case timestamp
        case value
        case unit
        case metadata
    }
}

struct HealthDataUploadResponse: Codable {
    let message: String
    let count: Int
    let dataType: String
}

// MARK: - Batch Upload

struct BatchUploadRequest: Codable {
    let uploads: [HealthDataUploadRequest]
}

struct BatchUploadResponse: Codable {
    let message: String
    let totalCount: Int
    let successCount: Int
    let failedCount: Int
}

// MARK: - Upload Error

struct UploadError: Error, LocalizedError {
    let message: String
    let statusCode: Int?

    var errorDescription: String? {
        if let code = statusCode {
            return "Upload failed (\(code)): \(message)"
        }
        return "Upload failed: \(message)"
    }
}
