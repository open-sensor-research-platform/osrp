package io.osrp.app.data.local.dao

import androidx.room.*
import io.osrp.app.data.local.entity.SensorReading
import io.osrp.app.data.local.entity.UploadStatus

/**
 * DAO for sensor readings table
 */
@Dao
interface SensorReadingDao {

    /**
     * Insert a single sensor reading
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(reading: SensorReading): Long

    /**
     * Insert multiple sensor readings
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(readings: List<SensorReading>): List<Long>

    /**
     * Update a sensor reading
     */
    @Update
    suspend fun update(reading: SensorReading)

    /**
     * Delete a sensor reading
     */
    @Delete
    suspend fun delete(reading: SensorReading)

    /**
     * Delete sensor readings by IDs
     */
    @Query("DELETE FROM sensor_readings WHERE id IN (:ids)")
    suspend fun deleteByIds(ids: List<Long>)

    /**
     * Get all sensor readings for a user
     */
    @Query("SELECT * FROM sensor_readings WHERE userId = :userId ORDER BY timestamp DESC")
    suspend fun getAllByUser(userId: String): List<SensorReading>

    /**
     * Get sensor readings by type
     */
    @Query("SELECT * FROM sensor_readings WHERE userId = :userId AND sensorType = :sensorType ORDER BY timestamp DESC")
    suspend fun getByType(userId: String, sensorType: String): List<SensorReading>

    /**
     * Get sensor readings in a time range
     */
    @Query("SELECT * FROM sensor_readings WHERE userId = :userId AND timestamp BETWEEN :startTime AND :endTime ORDER BY timestamp ASC")
    suspend fun getByTimeRange(userId: String, startTime: Long, endTime: Long): List<SensorReading>

    /**
     * Get pending sensor readings (not yet uploaded)
     */
    @Query("SELECT * FROM sensor_readings WHERE uploadStatus = ${UploadStatus.PENDING} ORDER BY timestamp ASC LIMIT :limit")
    suspend fun getPending(limit: Int = 100): List<SensorReading>

    /**
     * Get failed sensor readings (upload failed)
     */
    @Query("SELECT * FROM sensor_readings WHERE uploadStatus = ${UploadStatus.FAILED} AND retryCount < :maxRetries ORDER BY timestamp ASC LIMIT :limit")
    suspend fun getFailed(maxRetries: Int = 3, limit: Int = 100): List<SensorReading>

    /**
     * Update upload status
     */
    @Query("UPDATE sensor_readings SET uploadStatus = :status WHERE id IN (:ids)")
    suspend fun updateUploadStatus(ids: List<Long>, status: Int)

    /**
     * Update upload status with error message
     */
    @Query("UPDATE sensor_readings SET uploadStatus = :status, errorMessage = :errorMessage, retryCount = retryCount + 1 WHERE id IN (:ids)")
    suspend fun updateUploadStatusWithError(ids: List<Long>, status: Int, errorMessage: String)

    /**
     * Delete uploaded sensor readings older than specified timestamp
     */
    @Query("DELETE FROM sensor_readings WHERE uploadStatus = ${UploadStatus.UPLOADED} AND timestamp < :beforeTimestamp")
    suspend fun deleteUploadedBefore(beforeTimestamp: Long): Int

    /**
     * Get count of pending sensor readings
     */
    @Query("SELECT COUNT(*) FROM sensor_readings WHERE uploadStatus = ${UploadStatus.PENDING}")
    suspend fun getPendingCount(): Int

    /**
     * Delete all sensor readings (for testing)
     */
    @Query("DELETE FROM sensor_readings")
    suspend fun deleteAll()
}
