//
//  AuthViewModel.swift
//  OSRP
//
//  Authentication view model
//  Manages Cognito authentication state
//

import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userEmail: String? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let authService = AuthService()

    init() {
        // Check if user is already logged in
        Task {
            await checkAuthStatus()
        }
    }

    /// Check current authentication status
    func checkAuthStatus() async {
        isAuthenticated = await authService.isLoggedIn()
        if isAuthenticated {
            userEmail = await authService.getUserEmail()
        }
    }

    /// Login with email and password
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.login(email: email, password: password)
            isAuthenticated = true
            userEmail = email
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }

        isLoading = false
    }

    /// Logout
    func logout() {
        Task {
            await authService.logout()
            isAuthenticated = false
            userEmail = nil
        }
    }

    /// Refresh authentication token if needed
    func refreshTokenIfNeeded() async -> Bool {
        return await authService.refreshTokenIfNeeded()
    }

    /// Get authorization header for API requests
    func getAuthorizationHeader() async -> String? {
        return await authService.getAuthorizationHeader()
    }
}
