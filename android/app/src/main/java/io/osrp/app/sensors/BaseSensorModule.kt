package io.osrp.app.sensors

import kotlinx.coroutines.flow.Flow

/**
 * Base interface for all sensor modules
 * Defines common contract for sensor data collection
 */
interface BaseSensorModule {

    /**
     * Sensor type identifier (e.g., "accelerometer", "gyroscope", "location")
     */
    val sensorType: String

    /**
     * Sampling rate in Hz (samples per second)
     */
    val samplingRateHz: Int

    /**
     * Whether the sensor is currently collecting data
     */
    val isCollecting: Boolean

    /**
     * Start collecting sensor data
     */
    suspend fun startCollection()

    /**
     * Stop collecting sensor data
     */
    suspend fun stopCollection()

    /**
     * Check if the sensor is available on this device
     */
    fun isSensorAvailable(): Boolean

    /**
     * Get sensor status and configuration
     */
    fun getSensorStatus(): SensorStatus

    /**
     * Flow of sensor readings (for real-time monitoring)
     */
    fun getSensorReadingsFlow(): Flow<SensorData>
}

/**
 * Sensor status data class
 */
data class SensorStatus(
    val sensorType: String,
    val isAvailable: Boolean,
    val isCollecting: Boolean,
    val samplingRateHz: Int,
    val totalReadingsCollected: Long,
    val lastReadingTimestamp: Long?
)

/**
 * Sensor data class
 */
data class SensorData(
    val sensorType: String,
    val timestamp: Long,
    val values: Map<String, Float>,
    val accuracy: Int? = null
)
