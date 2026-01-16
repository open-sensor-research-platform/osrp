package io.osrp.app.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import io.osrp.app.data.local.converter.Converters

/**
 * Device state entity for Room database
 * Stores periodic snapshots of device state (battery, network, storage, etc.)
 */
@Entity(tableName = "device_states")
@TypeConverters(Converters::class)
data class DeviceState(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,

    /**
     * User/participant identifier
     */
    val userId: String,

    /**
     * Timestamp when state was captured (milliseconds since epoch)
     */
    val timestamp: Long,

    /**
     * Battery level (0-100)
     */
    val batteryLevel: Int,

    /**
     * Battery charging state
     */
    val isCharging: Boolean,

    /**
     * Network type (wifi, cellular, none)
     */
    val networkType: String,

    /**
     * Available storage in bytes
     */
    val availableStorage: Long,

    /**
     * Screen on/off state
     */
    val isScreenOn: Boolean,

    /**
     * Device orientation (portrait, landscape)
     */
    val orientation: String? = null,

    /**
     * Additional state information as JSON
     */
    val additionalInfo: String? = null,

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
