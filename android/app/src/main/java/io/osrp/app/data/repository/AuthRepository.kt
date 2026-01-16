package io.osrp.app.data.repository

import io.osrp.app.data.Result
import io.osrp.app.data.remote.LoginRequest
import io.osrp.app.data.remote.LoginResponse
import io.osrp.app.data.remote.OSRPApiService
import io.osrp.app.data.remote.RegisterRequest
import io.osrp.app.data.remote.RegisterResponse
import io.osrp.app.data.remote.RetrofitClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Repository for authentication operations
 * Handles user registration, login, and token management
 */
class AuthRepository(
    private val apiService: OSRPApiService = RetrofitClient.apiService
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
     * Login user and get tokens
     */
    suspend fun login(
        email: String,
        password: String
    ): Result<LoginResponse> = withContext(Dispatchers.IO) {
        try {
            val request = LoginRequest(email, password)
            val response = apiService.login(request)

            if (response.isSuccessful && response.body() != null) {
                Result.Success(response.body()!!)
            } else {
                Result.Error(Exception("Login failed: ${response.message()}"))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Save tokens to local storage
     * TODO: Implement with DataStore or EncryptedSharedPreferences
     */
    suspend fun saveTokens(loginResponse: LoginResponse) {
        // TODO: Save tokens securely
    }

    /**
     * Get stored ID token
     * TODO: Implement with DataStore or EncryptedSharedPreferences
     */
    suspend fun getIdToken(): String? {
        // TODO: Retrieve ID token from secure storage
        return null
    }

    /**
     * Check if user is logged in
     */
    suspend fun isLoggedIn(): Boolean {
        val token = getIdToken()
        return !token.isNullOrEmpty()
    }

    /**
     * Logout user
     */
    suspend fun logout() {
        // TODO: Clear stored tokens
    }
}
