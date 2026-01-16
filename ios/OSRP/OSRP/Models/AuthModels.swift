//
//  AuthModels.swift
//  OSRP
//
//  Authentication API request and response models
//

import Foundation

// MARK: - Login

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let accessToken: String
    let idToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
}

// MARK: - Register

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let studyCode: String
    let participantId: String
}

struct RegisterResponse: Codable {
    let message: String
    let userSub: String
    let userConfirmed: Bool
    let email: String
    let studyCode: String
    let participantId: String
}

// MARK: - Refresh Token

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

// MARK: - Error Response

struct ErrorResponse: Codable {
    let error: String
    let message: String
}
