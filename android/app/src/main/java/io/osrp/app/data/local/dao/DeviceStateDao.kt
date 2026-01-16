package io.osrp.app.data.local.dao

import androidx.room.*
import io.osrp.app.data.local.entity.DeviceState
import io.osrp.app.data.local.entity.UploadStatus

/**
 * DAO for device states table
 */
@Dao
interface DeviceStateDao {

    /**
     * Insert a single device state
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(state: DeviceState): Long

    /**
     * Insert multiple device states
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(states: List<DeviceState>): List<Long>

    /**
     * Update a device state
     */
    @Update
    suspend fun update(state: DeviceState)

    /**
     * Delete a device state
     */
    @Delete
    suspend fun delete(state: DeviceState)

    /**
     * Delete device states by IDs
     */
    @Query("DELETE FROM device_states WHERE id IN (:ids)")
    suspend fun deleteByIds(ids: List<Long>)

    /**
     * Get all device states for a user
     */
    @Query("SELECT * FROM device_states WHERE userId = :userId ORDER BY timestamp DESC")
    suspend fun getAllByUser(userId: String): List<DeviceState>

    /**
     * Get device states in a time range
     */
    @Query("SELECT * FROM device_states WHERE userId = :userId AND timestamp BETWEEN :startTime AND :endTime ORDER BY timestamp ASC")
    suspend fun getByTimeRange(userId: String, startTime: Long, endTime: Long): List<DeviceState>

    /**
     * Get the most recent device state
     */
    @Query("SELECT * FROM device_states WHERE userId = :userId ORDER BY timestamp DESC LIMIT 1")
    suspend fun getLatest(userId: String): DeviceState?

    /**
     * Get pending device states (not yet uploaded)
     */
    @Query("SELECT * FROM device_states WHERE uploadStatus = ${UploadStatus.PENDING} ORDER BY timestamp ASC LIMIT :limit")
    suspend fun getPending(limit: Int = 100): List<DeviceState>

    /**
     * Get failed device states (upload failed)
     */
    @Query("SELECT * FROM device_states WHERE uploadStatus = ${UploadStatus.FAILED} AND retryCount < :maxRetries ORDER BY timestamp ASC LIMIT :limit")
    suspend fun getFailed(maxRetries: Int = 3, limit: Int = 100): List<DeviceState>

    /**
     * Update upload status
     */
    @Query("UPDATE device_states SET uploadStatus = :status WHERE id IN (:ids)")
    suspend fun updateUploadStatus(ids: List<Long>, status: Int)

    /**
     * Update upload status with error message
     */
    @Query("UPDATE device_states SET uploadStatus = :status, errorMessage = :errorMessage, retryCount = retryCount + 1 WHERE id IN (:ids)")
    suspend fun updateUploadStatusWithError(ids: List<Long>, status: Int, errorMessage: String)

    /**
     * Delete uploaded device states older than specified timestamp
     */
    @Query("DELETE FROM device_states WHERE uploadStatus = ${UploadStatus.UPLOADED} AND timestamp < :beforeTimestamp")
    suspend fun deleteUploadedBefore(beforeTimestamp: Long): Int

    /**
     * Get count of pending device states
     */
    @Query("SELECT COUNT(*) FROM device_states WHERE uploadStatus = ${UploadStatus.PENDING}")
    suspend fun getPendingCount(): Int

    /**
     * Delete all device states (for testing)
     */
    @Query("DELETE FROM device_states")
    suspend fun deleteAll()
}
