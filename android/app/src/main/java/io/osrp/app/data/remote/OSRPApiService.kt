package io.osrp.app.data.remote

import retrofit2.Response
import retrofit2.http.*

/**
 * Retrofit API service interface for OSRP backend
 * Defines endpoints for authentication and data upload
 */
interface OSRPApiService {

    // Authentication Endpoints

    @POST("auth/register")
    suspend fun register(@Body request: RegisterRequest): Response<RegisterResponse>

    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): Response<LoginResponse>

    @POST("auth/refresh")
    suspend fun refreshToken(@Body request: RefreshTokenRequest): Response<LoginResponse>

    // Data Upload Endpoints

    @POST("data/sensor")
    suspend fun uploadSensorData(
        @Header("Authorization") token: String,
        @Body data: SensorDataRequest
    ): Response<SensorDataResponse>

    @POST("data/event")
    suspend fun uploadEvent(
        @Header("Authorization") token: String,
        @Body event: EventRequest
    ): Response<EventResponse>

    @POST("data/device-state")
    suspend fun uploadDeviceState(
        @Header("Authorization") token: String,
        @Body state: DeviceStateRequest
    ): Response<DeviceStateResponse>

    @GET("data/presigned-url")
    suspend fun getPresignedUrl(
        @Header("Authorization") token: String,
        @Query("key") key: String,
        @Query("contentType") contentType: String
    ): Response<PresignedUrlResponse>
}

// Request/Response Models

data class RegisterRequest(
    val email: String,
    val password: String,
    val studyCode: String,
    val participantId: String
)

data class RegisterResponse(
    val message: String,
    val userSub: String,
    val userConfirmed: Boolean,
    val email: String,
    val studyCode: String,
    val participantId: String
)

data class LoginRequest(
    val email: String,
    val password: String
)

data class LoginResponse(
    val accessToken: String,
    val idToken: String,
    val refreshToken: String,
    val expiresIn: Int,
    val tokenType: String
)

data class RefreshTokenRequest(
    val refreshToken: String
)

data class SensorDataRequest(
    val sensorType: String,
    val readings: List<SensorReading>,
    val studyCode: String
)

data class SensorReading(
    val timestamp: Long,
    val data: Map<String, Float>,
    val accuracy: Int
)

data class SensorDataResponse(
    val message: String,
    val count: Int,
    val sensorType: String
)

data class EventRequest(
    val eventType: String,
    val timestamp: Long,
    val studyCode: String,
    val metadata: Map<String, Any>? = null
)

data class EventResponse(
    val message: String,
    val eventType: String,
    val timestamp: Long
)

data class DeviceStateRequest(
    val timestamp: Long,
    val studyCode: String,
    val deviceInfo: Map<String, Any>,
    val batteryLevel: Float,
    val storageAvailable: Long,
    val networkType: String
)

data class DeviceStateResponse(
    val message: String,
    val timestamp: Long
)

data class PresignedUrlResponse(
    val uploadUrl: String,
    val key: String,
    val expiresIn: Int
)
