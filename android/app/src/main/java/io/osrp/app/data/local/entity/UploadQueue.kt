package io.osrp.app.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Upload queue entity for Room database
 * Tracks batches of data ready for upload
 */
@Entity(tableName = "upload_queue")
data class UploadQueue(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,

    /**
     * User/participant identifier
     */
    val userId: String,

    /**
     * Data type being uploaded (sensor_readings, events, device_states)
     */
    val dataType: String,

    /**
     * Batch identifier - groups related items together
     */
    val batchId: String,

    /**
     * Number of items in this batch
     */
    val itemCount: Int,

    /**
     * Timestamp when batch was created (milliseconds since epoch)
     */
    val createdAt: Long,

    /**
     * Timestamp when upload should be attempted (milliseconds since epoch)
     * Allows for delayed retries with backoff
     */
    val scheduledAt: Long,

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
    val errorMessage: String? = null,

    /**
     * Priority (higher = more urgent)
     */
    val priority: Int = 0
)
