package io.osrp.app.data.local

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

/**
 * Secure storage for authentication tokens using EncryptedSharedPreferences
 * Provides encrypted storage for sensitive authentication data
 */
class SecureTokenStorage(context: Context) {

    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val sharedPreferences: SharedPreferences = EncryptedSharedPreferences.create(
        context,
        PREFS_NAME,
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    /**
     * Save authentication tokens
     */
    fun saveTokens(accessToken: String, idToken: String, refreshToken: String, expiresIn: Int) {
        val expirationTime = System.currentTimeMillis() + (expiresIn * 1000L)

        sharedPreferences.edit().apply {
            putString(KEY_ACCESS_TOKEN, accessToken)
            putString(KEY_ID_TOKEN, idToken)
            putString(KEY_REFRESH_TOKEN, refreshToken)
            putLong(KEY_EXPIRATION_TIME, expirationTime)
            apply()
        }
    }

    /**
     * Get ID token (used for API authentication)
     * IMPORTANT: API Gateway validates ID token, not access token
     */
    fun getIdToken(): String? {
        return sharedPreferences.getString(KEY_ID_TOKEN, null)
    }

    /**
     * Get access token
     */
    fun getAccessToken(): String? {
        return sharedPreferences.getString(KEY_ACCESS_TOKEN, null)
    }

    /**
     * Get refresh token
     */
    fun getRefreshToken(): String? {
        return sharedPreferences.getString(KEY_REFRESH_TOKEN, null)
    }

    /**
     * Check if ID token is expired
     */
    fun isTokenExpired(): Boolean {
        val expirationTime = sharedPreferences.getLong(KEY_EXPIRATION_TIME, 0)
        // Add 5-minute buffer to refresh before actual expiration
        return System.currentTimeMillis() >= (expirationTime - TOKEN_REFRESH_BUFFER)
    }

    /**
     * Check if user is logged in
     */
    fun isLoggedIn(): Boolean {
        val idToken = getIdToken()
        return !idToken.isNullOrEmpty() && !isTokenExpired()
    }

    /**
     * Clear all tokens (logout)
     */
    fun clearTokens() {
        sharedPreferences.edit().apply {
            remove(KEY_ACCESS_TOKEN)
            remove(KEY_ID_TOKEN)
            remove(KEY_REFRESH_TOKEN)
            remove(KEY_EXPIRATION_TIME)
            apply()
        }
    }

    /**
     * Save user email (for convenience)
     */
    fun saveUserEmail(email: String) {
        sharedPreferences.edit().putString(KEY_USER_EMAIL, email).apply()
    }

    /**
     * Get saved user email
     */
    fun getUserEmail(): String? {
        return sharedPreferences.getString(KEY_USER_EMAIL, null)
    }

    companion object {
        private const val PREFS_NAME = "osrp_secure_prefs"
        private const val KEY_ACCESS_TOKEN = "access_token"
        private const val KEY_ID_TOKEN = "id_token"
        private const val KEY_REFRESH_TOKEN = "refresh_token"
        private const val KEY_EXPIRATION_TIME = "expiration_time"
        private const val KEY_USER_EMAIL = "user_email"

        // Refresh token 5 minutes before expiration
        private const val TOKEN_REFRESH_BUFFER = 5 * 60 * 1000L // 5 minutes in milliseconds
    }
}
