package io.osrp.app.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import io.osrp.app.data.local.converter.Converters

/**
 * Event entity for Room database
 * Stores user events (app opened, button clicked, survey completed, etc.)
 */
@Entity(tableName = "events")
@TypeConverters(Converters::class)
data class Event(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,

    /**
     * User/participant identifier
     */
    val userId: String,

    /**
     * Event type (app_opened, screen_changed, survey_completed, etc.)
     */
    val eventType: String,

    /**
     * Timestamp when event occurred (milliseconds since epoch)
     */
    val timestamp: Long,

    /**
     * Event properties as JSON string
     * Example: {"screen": "home", "duration_ms": 5000}
     */
    val properties: String? = null,

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
