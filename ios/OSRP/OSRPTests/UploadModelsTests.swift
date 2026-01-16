//
//  UploadModelsTests.swift
//  OSRPTests
//
//  Unit tests for upload API models
//

import XCTest
@testable import OSRP

final class UploadModelsTests: XCTestCase {

    func testHealthReadingEncoding() throws {
        let reading = HealthReading(
            timestamp: 1234567890000,
            value: 10000.0,
            unit: "count",
            metadata: ["source": "HealthKit"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(reading)

        XCTAssertFalse(data.isEmpty)

        // Verify JSON structure
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["timestamp"] as? Int64, 1234567890000)
        XCTAssertEqual(json?["value"] as? Double, 10000.0)
        XCTAssertEqual(json?["unit"] as? String, "count")
    }

    func testHealthReadingDecoding() throws {
        let json = """
        {
            "timestamp": 1234567890000,
            "value": 72.5,
            "unit": "bpm"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let reading = try decoder.decode(HealthReading.self, from: json)

        XCTAssertEqual(reading.timestamp, 1234567890000)
        XCTAssertEqual(reading.value, 72.5)
        XCTAssertEqual(reading.unit, "bpm")
        XCTAssertNil(reading.metadata)
    }

    func testHealthDataUploadRequestEncoding() throws {
        let readings = [
            HealthReading(timestamp: 1000, value: 100.0, unit: "count", metadata: nil),
            HealthReading(timestamp: 2000, value: 200.0, unit: "count", metadata: nil)
        ]

        let request = HealthDataUploadRequest(
            dataType: "steps",
            readings: readings,
            studyCode: "test-study"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)

        XCTAssertFalse(data.isEmpty)

        // Verify JSON structure
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["dataType"] as? String, "steps")
        XCTAssertEqual(json?["studyCode"] as? String, "test-study")

        let readingsArray = json?["readings"] as? [[String: Any]]
        XCTAssertEqual(readingsArray?.count, 2)
    }

    func testHealthDataUploadResponseDecoding() throws {
        let json = """
        {
            "message": "Upload successful",
            "count": 10,
            "dataType": "steps"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(HealthDataUploadResponse.self, from: json)

        XCTAssertEqual(response.message, "Upload successful")
        XCTAssertEqual(response.count, 10)
        XCTAssertEqual(response.dataType, "steps")
    }

    func testBatchUploadRequestEncoding() throws {
        let readings1 = [HealthReading(timestamp: 1000, value: 100.0, unit: "count", metadata: nil)]
        let readings2 = [HealthReading(timestamp: 2000, value: 72.0, unit: "bpm", metadata: nil)]

        let uploads = [
            HealthDataUploadRequest(dataType: "steps", readings: readings1, studyCode: nil),
            HealthDataUploadRequest(dataType: "heart_rate", readings: readings2, studyCode: nil)
        ]

        let batchRequest = BatchUploadRequest(uploads: uploads)

        let encoder = JSONEncoder()
        let data = try encoder.encode(batchRequest)

        XCTAssertFalse(data.isEmpty)

        // Verify JSON structure
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)

        let uploadsArray = json?["uploads"] as? [[String: Any]]
        XCTAssertEqual(uploadsArray?.count, 2)
    }

    func testBatchUploadResponseDecoding() throws {
        let json = """
        {
            "message": "Batch upload completed",
            "totalCount": 100,
            "successCount": 95,
            "failedCount": 5
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(BatchUploadResponse.self, from: json)

        XCTAssertEqual(response.message, "Batch upload completed")
        XCTAssertEqual(response.totalCount, 100)
        XCTAssertEqual(response.successCount, 95)
        XCTAssertEqual(response.failedCount, 5)
    }

    func testUploadErrorDescription() {
        let error1 = UploadError(message: "Network error", statusCode: nil)
        XCTAssertEqual(error1.errorDescription, "Upload failed: Network error")

        let error2 = UploadError(message: "Server error", statusCode: 500)
        XCTAssertEqual(error2.errorDescription, "Upload failed (500): Server error")
    }
}
