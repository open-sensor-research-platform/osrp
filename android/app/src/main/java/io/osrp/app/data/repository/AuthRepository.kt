package io.osrp.app.data.repository

import android.content.Context
import io.osrp.app.data.Result
import io.osrp.app.data.local.SecureTokenStorage
import io.osrp.app.data.remote.LoginRequest
import io.osrp.app.data.remote.LoginResponse
import io.osrp.app.data.remote.OSRPApiService
import io.osrp.app.data.remote.RefreshTokenRequest
import io.osrp.app.data.remote.RegisterRequest
import io.osrp.app.data.remote.RegisterResponse
import io.osrp.app.data.remote.RetrofitClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Repository for authentication operations
 * Handles user registration, login, token management, and logout
 */
class AuthRepository(
    context: Context,
    private val apiService: OSRPApiService = RetrofitClient.apiService,
    private val tokenStorage: SecureTokenStorage = SecureTokenStorage(context)
) {

    /**
     * Register a new user
     */
    suspend fun register(
        email: String,
        password: String,
        studyCode: String,
        participantId: String
    ): Result<RegisterResponse> = withContext(Dispatchers.IO) {
        try {
            val request = RegisterRequest(email, password, studyCode, participantId)
            val response = apiService.register(request)

            if (response.isSuccessful && response.body() != null) {
                Result.Success(response.body()!!)
            } else {
                Result.Error(Exception("Registration failed: ${response.message()}"))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Login user and store tokens securely
     */
    suspend fun login(
        email: String,
        password: String
    ): Result<LoginResponse> = withContext(Dispatchers.IO) {
        try {
            val request = LoginRequest(email, password)
            val response = apiService.login(request)

            if (response.isSuccessful && response.body() != null) {
                val loginResponse = response.body()!!

                // Save tokens securely
                tokenStorage.saveTokens(
                    accessToken = loginResponse.accessToken,
                    idToken = loginResponse.idToken,
                    refreshToken = loginResponse.refreshToken,
                    expiresIn = loginResponse.expiresIn
                )

                // Save user email for convenience
                tokenStorage.saveUserEmail(email)

                Result.Success(loginResponse)
            } else {
                Result.Error(Exception("Login failed: ${response.message()}"))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Refresh tokens if expired
     * Returns true if refresh was successful or not needed
     */
    suspend fun refreshTokenIfNeeded(): Boolean = withContext(Dispatchers.IO) {
        try {
            // Check if token needs refresh
            if (!tokenStorage.isTokenExpired()) {
                return@withContext true
            }

            val refreshToken = tokenStorage.getRefreshToken()
            if (refreshToken.isNullOrEmpty()) {
                return@withContext false
            }

            // Call refresh endpoint
            val request = RefreshTokenRequest(refreshToken)
            val response = apiService.refreshToken(request)

            if (response.isSuccessful && response.body() != null) {
                val loginResponse = response.body()!!

                // Update tokens
                tokenStorage.saveTokens(
                    accessToken = loginResponse.accessToken,
                    idToken = loginResponse.idToken,
                    refreshToken = loginResponse.refreshToken,
                    expiresIn = loginResponse.expiresIn
                )

                true
            } else {
                // Refresh failed - user needs to login again
                logout()
                false
            }
        } catch (e: Exception) {
            // Refresh failed - user needs to login again
            logout()
            false
        }
    }

    /**
     * Get ID token for API calls
     * IMPORTANT: Use ID token, not access token, for API Gateway authentication
     * Automatically refreshes if expired
     */
    suspend fun getIdToken(): String? {
        refreshTokenIfNeeded()
        return tokenStorage.getIdToken()
    }

    /**
     * Get ID token with Bearer prefix for Authorization header
     */
    suspend fun getAuthorizationHeader(): String? {
        val idToken = getIdToken()
        return if (idToken != null) "Bearer $idToken" else null
    }

    /**
     * Check if user is logged in
     */
    fun isLoggedIn(): Boolean {
        return tokenStorage.isLoggedIn()
    }

    /**
     * Get stored user email
     */
    fun getUserEmail(): String? {
        return tokenStorage.getUserEmail()
    }

    /**
     * Logout user - clear all tokens
     */
    fun logout() {
        tokenStorage.clearTokens()
    }
}
