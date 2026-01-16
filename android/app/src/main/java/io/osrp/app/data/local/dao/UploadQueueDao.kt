package io.osrp.app.data.local.dao

import androidx.room.*
import io.osrp.app.data.local.entity.UploadQueue
import io.osrp.app.data.local.entity.UploadStatus

/**
 * DAO for upload queue table
 */
@Dao
interface UploadQueueDao {

    /**
     * Insert a single upload queue item
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(item: UploadQueue): Long

    /**
     * Insert multiple upload queue items
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(items: List<UploadQueue>): List<Long>

    /**
     * Update an upload queue item
     */
    @Update
    suspend fun update(item: UploadQueue)

    /**
     * Delete an upload queue item
     */
    @Delete
    suspend fun delete(item: UploadQueue)

    /**
     * Delete upload queue items by IDs
     */
    @Query("DELETE FROM upload_queue WHERE id IN (:ids)")
    suspend fun deleteByIds(ids: List<Long>)

    /**
     * Delete upload queue items by batch ID
     */
    @Query("DELETE FROM upload_queue WHERE batchId = :batchId")
    suspend fun deleteByBatchId(batchId: String)

    /**
     * Get all upload queue items
     */
    @Query("SELECT * FROM upload_queue ORDER BY priority DESC, scheduledAt ASC")
    suspend fun getAll(): List<UploadQueue>

    /**
     * Get pending upload queue items (ready to upload)
     */
    @Query("SELECT * FROM upload_queue WHERE uploadStatus = ${UploadStatus.PENDING} AND scheduledAt <= :currentTime ORDER BY priority DESC, scheduledAt ASC LIMIT :limit")
    suspend fun getPending(currentTime: Long, limit: Int = 10): List<UploadQueue>

    /**
     * Get failed upload queue items (for retry)
     */
    @Query("SELECT * FROM upload_queue WHERE uploadStatus = ${UploadStatus.FAILED} AND retryCount < :maxRetries AND scheduledAt <= :currentTime ORDER BY priority DESC, scheduledAt ASC LIMIT :limit")
    suspend fun getFailed(currentTime: Long, maxRetries: Int = 3, limit: Int = 10): List<UploadQueue>

    /**
     * Get upload queue item by batch ID
     */
    @Query("SELECT * FROM upload_queue WHERE batchId = :batchId LIMIT 1")
    suspend fun getByBatchId(batchId: String): UploadQueue?

    /**
     * Update upload status
     */
    @Query("UPDATE upload_queue SET uploadStatus = :status WHERE id = :id")
    suspend fun updateUploadStatus(id: Long, status: Int)

    /**
     * Update upload status with error message
     */
    @Query("UPDATE upload_queue SET uploadStatus = :status, errorMessage = :errorMessage, retryCount = retryCount + 1, scheduledAt = :nextScheduledAt WHERE id = :id")
    suspend fun updateUploadStatusWithError(id: Long, status: Int, errorMessage: String, nextScheduledAt: Long)

    /**
     * Delete uploaded items older than specified timestamp
     */
    @Query("DELETE FROM upload_queue WHERE uploadStatus = ${UploadStatus.UPLOADED} AND createdAt < :beforeTimestamp")
    suspend fun deleteUploadedBefore(beforeTimestamp: Long): Int

    /**
     * Get count of pending upload queue items
     */
    @Query("SELECT COUNT(*) FROM upload_queue WHERE uploadStatus = ${UploadStatus.PENDING}")
    suspend fun getPendingCount(): Int

    /**
     * Delete all upload queue items (for testing)
     */
    @Query("DELETE FROM upload_queue")
    suspend fun deleteAll()
}
