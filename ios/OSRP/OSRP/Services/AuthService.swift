//
//  AuthService.swift
//  OSRP
//
//  Authentication service
//  Handles AWS Cognito authentication via REST API
//

import Foundation

actor AuthService {
    private let keychain = KeychainManager.shared
    private let baseURL: String
    private let session: URLSession

    /// Token expiration buffer (5 minutes in seconds)
    private let tokenExpirationBuffer: TimeInterval = 300

    init(baseURL: String = Config.apiBaseURL) {
        self.baseURL = baseURL

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = Config.requestTimeout
        configuration.timeoutIntervalForResource = Config.requestTimeout
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Public Methods

    /// Check if user is logged in
    func isLoggedIn() async -> Bool {
        do {
            _ = try keychain.retrieve(key: KeychainManager.Keys.idToken)
            return true
        } catch {
            return false
        }
    }

    /// Get current user email
    func getUserEmail() async -> String? {
        do {
            return try keychain.retrieve(key: KeychainManager.Keys.userEmail)
        } catch {
            return nil
        }
    }

    /// Login with email and password
    func login(email: String, password: String) async throws {
        let request = LoginRequest(email: email, password: password)

        guard let url = URL(string: "\(baseURL)auth/login") else {
            throw AuthError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw AuthError.unknown(error)
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }

            // Check for errors
            if httpResponse.statusCode == 401 {
                throw AuthError.invalidCredentials
            }

            guard httpResponse.statusCode == 200 else {
                // Try to parse error response
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw AuthError.serverError(errorResponse.message)
                }
                throw AuthError.serverError("Login failed with status \(httpResponse.statusCode)")
            }

            // Parse success response
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)

            // Save tokens to Keychain
            try saveTokens(loginResponse: loginResponse, email: email)

        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError
        }
    }

    /// Register new user
    func register(email: String, password: String, studyCode: String, participantId: String) async throws {
        let request = RegisterRequest(
            email: email,
            password: password,
            studyCode: studyCode,
            participantId: participantId
        )

        guard let url = URL(string: "\(baseURL)auth/register") else {
            throw AuthError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw AuthError.unknown(error)
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }

            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                // Try to parse error response
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw AuthError.serverError(errorResponse.message)
                }
                throw AuthError.serverError("Registration failed with status \(httpResponse.statusCode)")
            }

            // Registration successful
            _ = try JSONDecoder().decode(RegisterResponse.self, from: data)

        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError
        }
    }

    /// Logout - clear all tokens
    func logout() async {
        do {
            try keychain.deleteAll()
        } catch {
            // Ignore errors during logout
            print("Error clearing keychain: \(error)")
        }
    }

    /// Refresh authentication token if needed
    /// Returns true if refresh was successful or not needed
    func refreshTokenIfNeeded() async -> Bool {
        do {
            // Check if token is expired
            if !isTokenExpired() {
                return true
            }

            // Get refresh token
            guard let refreshToken = try? keychain.retrieve(key: KeychainManager.Keys.refreshToken) else {
                return false
            }

            let request = RefreshTokenRequest(refreshToken: refreshToken)

            guard let url = URL(string: "\(baseURL)auth/refresh") else {
                return false
            }

            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                urlRequest.httpBody = try JSONEncoder().encode(request)
            } catch {
                return false
            }

            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }

            guard httpResponse.statusCode == 200 else {
                // Refresh failed - logout
                await logout()
                return false
            }

            // Parse response
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)

            // Get current email
            let email = try? keychain.retrieve(key: KeychainManager.Keys.userEmail)

            // Save new tokens
            try saveTokens(loginResponse: loginResponse, email: email ?? "")

            return true

        } catch {
            // Refresh failed - logout
            await logout()
            return false
        }
    }

    /// Get ID token for API calls
    /// IMPORTANT: Use ID token, not access token, for API Gateway authentication
    func getIdToken() async -> String? {
        // Refresh if needed
        _ = await refreshTokenIfNeeded()

        do {
            return try keychain.retrieve(key: KeychainManager.Keys.idToken)
        } catch {
            return nil
        }
    }

    /// Get authorization header for API requests
    func getAuthorizationHeader() async -> String? {
        guard let idToken = await getIdToken() else { return nil }
        return "Bearer \(idToken)"
    }

    // MARK: - Private Methods

    /// Save tokens to Keychain
    private func saveTokens(loginResponse: LoginResponse, email: String) throws {
        do {
            try keychain.save(key: KeychainManager.Keys.accessToken, value: loginResponse.accessToken)
            try keychain.save(key: KeychainManager.Keys.idToken, value: loginResponse.idToken)
            try keychain.save(key: KeychainManager.Keys.refreshToken, value: loginResponse.refreshToken)
            try keychain.save(key: KeychainManager.Keys.userEmail, value: email)

            // Calculate expiration time
            let expirationTime = Date().timeIntervalSince1970 + Double(loginResponse.expiresIn)
            try keychain.save(key: KeychainManager.Keys.tokenExpiration, value: String(expirationTime))
        } catch {
            throw AuthError.keychainError(error as? KeychainError ?? KeychainError.unexpectedStatus(0))
        }
    }

    /// Check if token is expired
    private func isTokenExpired() -> Bool {
        guard let expirationString = try? keychain.retrieve(key: KeychainManager.Keys.tokenExpiration),
              let expirationTime = Double(expirationString) else {
            return true
        }

        let currentTime = Date().timeIntervalSince1970
        let timeUntilExpiration = expirationTime - currentTime

        // Return true if token expires within buffer time (5 minutes)
        return timeUntilExpiration < tokenExpirationBuffer
    }
}
