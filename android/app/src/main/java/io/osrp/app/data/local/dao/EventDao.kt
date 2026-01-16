package io.osrp.app.data.local.dao

import androidx.room.*
import io.osrp.app.data.local.entity.Event
import io.osrp.app.data.local.entity.UploadStatus

/**
 * DAO for events table
 */
@Dao
interface EventDao {

    /**
     * Insert a single event
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(event: Event): Long

    /**
     * Insert multiple events
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(events: List<Event>): List<Long>

    /**
     * Update an event
     */
    @Update
    suspend fun update(event: Event)

    /**
     * Delete an event
     */
    @Delete
    suspend fun delete(event: Event)

    /**
     * Delete events by IDs
     */
    @Query("DELETE FROM events WHERE id IN (:ids)")
    suspend fun deleteByIds(ids: List<Long>)

    /**
     * Get all events for a user
     */
    @Query("SELECT * FROM events WHERE userId = :userId ORDER BY timestamp DESC")
    suspend fun getAllByUser(userId: String): List<Event>

    /**
     * Get events by type
     */
    @Query("SELECT * FROM events WHERE userId = :userId AND eventType = :eventType ORDER BY timestamp DESC")
    suspend fun getByType(userId: String, eventType: String): List<Event>

    /**
     * Get events in a time range
     */
    @Query("SELECT * FROM events WHERE userId = :userId AND timestamp BETWEEN :startTime AND :endTime ORDER BY timestamp ASC")
    suspend fun getByTimeRange(userId: String, startTime: Long, endTime: Long): List<Event>

    /**
     * Get pending events (not yet uploaded)
     */
    @Query("SELECT * FROM events WHERE uploadStatus = ${UploadStatus.PENDING} ORDER BY timestamp ASC LIMIT :limit")
    suspend fun getPending(limit: Int = 100): List<Event>

    /**
     * Get failed events (upload failed)
     */
    @Query("SELECT * FROM events WHERE uploadStatus = ${UploadStatus.FAILED} AND retryCount < :maxRetries ORDER BY timestamp ASC LIMIT :limit")
    suspend fun getFailed(maxRetries: Int = 3, limit: Int = 100): List<Event>

    /**
     * Update upload status
     */
    @Query("UPDATE events SET uploadStatus = :status WHERE id IN (:ids)")
    suspend fun updateUploadStatus(ids: List<Long>, status: Int)

    /**
     * Update upload status with error message
     */
    @Query("UPDATE events SET uploadStatus = :status, errorMessage = :errorMessage, retryCount = retryCount + 1 WHERE id IN (:ids)")
    suspend fun updateUploadStatusWithError(ids: List<Long>, status: Int, errorMessage: String)

    /**
     * Delete uploaded events older than specified timestamp
     */
    @Query("DELETE FROM events WHERE uploadStatus = ${UploadStatus.UPLOADED} AND timestamp < :beforeTimestamp")
    suspend fun deleteUploadedBefore(beforeTimestamp: Long): Int

    /**
     * Get count of pending events
     */
    @Query("SELECT COUNT(*) FROM events WHERE uploadStatus = ${UploadStatus.PENDING}")
    suspend fun getPendingCount(): Int

    /**
     * Delete all events (for testing)
     */
    @Query("DELETE FROM events")
    suspend fun deleteAll()
}
