//
//  AuthError.swift
//  OSRP
//
//  Authentication error types
//

import Foundation

enum AuthError: LocalizedError {
    case invalidCredentials
    case networkError
    case serverError(String)
    case tokenExpired
    case invalidResponse
    case keychainError(KeychainError)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .serverError(let message):
            return message
        case .tokenExpired:
            return "Your session has expired. Please login again."
        case .invalidResponse:
            return "Invalid response from server"
        case .keychainError(let error):
            return "Keychain error: \(error.localizedDescription)"
        case .unknown(let error):
            return "An error occurred: \(error.localizedDescription)"
        }
    }
}
