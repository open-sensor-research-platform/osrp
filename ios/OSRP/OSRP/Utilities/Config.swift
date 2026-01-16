//
//  Config.swift
//  OSRP
//
//  Configuration for AWS services
//

import Foundation

struct Config {
    /// AWS API Gateway endpoint
    /// Replace with your actual API Gateway URL after deploying infrastructure
    static let apiBaseURL = "https://your-api-gateway-url.execute-api.us-west-2.amazonaws.com/dev/"

    /// AWS Region
    static let region = "us-west-2"

    /// Request timeout
    static let requestTimeout: TimeInterval = 30.0
}
