package io.osrp.app.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import io.osrp.app.data.local.converter.Converters

/**
 * Sensor reading entity for Room database
 * Stores raw sensor data before upload
 */
@Entity(tableName = "sensor_readings")
@TypeConverters(Converters::class)
data class SensorReading(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,

    /**
     * User/participant identifier
     */
    val userId: String,

    /**
     * Type of sensor (accelerometer, gyroscope, location, heart_rate, etc.)
     */
    val sensorType: String,

    /**
     * Timestamp when reading was captured (milliseconds since epoch)
     */
    val timestamp: Long,

    /**
     * Sensor reading values as JSON string
     * Example for accelerometer: {"x": 0.5, "y": 0.2, "z": 9.8}
     * Example for location: {"lat": 37.7749, "lon": -122.4194, "accuracy": 10.0}
     */
    val values: String,

    /**
     * Additional metadata as JSON string
     * Example: {"device_id": "abc123", "os_version": "13", "battery_level": 85}
     */
    val metadata: String? = null,

    /**
     * Upload status
     * 0 = pending, 1 = uploading, 2 = uploaded, 3 = failed
     */
    val uploadStatus: Int = 0,

    /**
     * Number of upload retry attempts
     */
    val retryCount: Int = 0,

    /**
     * Error message if upload failed
     */
    val errorMessage: String? = null
)

/**
 * Upload status constants
 */
object UploadStatus {
    const val PENDING = 0
    const val UPLOADING = 1
    const val UPLOADED = 2
    const val FAILED = 3
}
