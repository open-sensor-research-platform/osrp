package io.osrp.app.data.repository

import android.content.Context
import io.osrp.app.data.Result
import io.osrp.app.data.local.OSRPDatabase
import io.osrp.app.data.local.entity.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.UUID

/**
 * Data Repository
 * Provides a clean API for data operations using Repository pattern
 */
class DataRepository(
    context: Context,
    private val database: OSRPDatabase = OSRPDatabase.getInstance(context)
) {

    // DAOs
    private val sensorReadingDao = database.sensorReadingDao()
    private val eventDao = database.eventDao()
    private val deviceStateDao = database.deviceStateDao()
    private val uploadQueueDao = database.uploadQueueDao()

    // ============================================================
    // Sensor Reading Operations
    // ============================================================

    /**
     * Insert a sensor reading
     */
    suspend fun insertSensorReading(reading: SensorReading): Result<Long> = withContext(Dispatchers.IO) {
        try {
            val id = sensorReadingDao.insert(reading)
            Result.Success(id)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Insert multiple sensor readings
     */
    suspend fun insertSensorReadings(readings: List<SensorReading>): Result<List<Long>> = withContext(Dispatchers.IO) {
        try {
            val ids = sensorReadingDao.insertAll(readings)
            Result.Success(ids)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Get sensor readings by type
     */
    suspend fun getSensorReadingsByType(userId: String, sensorType: String): Result<List<SensorReading>> = withContext(Dispatchers.IO) {
        try {
            val readings = sensorReadingDao.getByType(userId, sensorType)
            Result.Success(readings)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Get sensor readings in time range
     */
    suspend fun getSensorReadingsByTimeRange(userId: String, startTime: Long, endTime: Long): Result<List<SensorReading>> = withContext(Dispatchers.IO) {
        try {
            val readings = sensorReadingDao.getByTimeRange(userId, startTime, endTime)
            Result.Success(readings)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Get pending sensor readings (ready for upload)
     */
    suspend fun getPendingSensorReadings(limit: Int = 100): Result<List<SensorReading>> = withContext(Dispatchers.IO) {
        try {
            val readings = sensorReadingDao.getPending(limit)
            Result.Success(readings)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Update sensor reading upload status
     */
    suspend fun updateSensorReadingUploadStatus(ids: List<Long>, status: Int): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            sensorReadingDao.updateUploadStatus(ids, status)
            Result.Success(Unit)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Delete uploaded sensor readings older than specified time
     */
    suspend fun deleteOldSensorReadings(beforeTimestamp: Long): Result<Int> = withContext(Dispatchers.IO) {
        try {
            val count = sensorReadingDao.deleteUploadedBefore(beforeTimestamp)
            Result.Success(count)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    // ============================================================
    // Event Operations
    // ============================================================

    /**
     * Insert an event
     */
    suspend fun insertEvent(event: Event): Result<Long> = withContext(Dispatchers.IO) {
        try {
            val id = eventDao.insert(event)
            Result.Success(id)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Insert multiple events
     */
    suspend fun insertEvents(events: List<Event>): Result<List<Long>> = withContext(Dispatchers.IO) {
        try {
            val ids = eventDao.insertAll(events)
            Result.Success(ids)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Get events by type
     */
    suspend fun getEventsByType(userId: String, eventType: String): Result<List<Event>> = withContext(Dispatchers.IO) {
        try {
            val events = eventDao.getByType(userId, eventType)
            Result.Success(events)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Get pending events (ready for upload)
     */
    suspend fun getPendingEvents(limit: Int = 100): Result<List<Event>> = withContext(Dispatchers.IO) {
        try {
            val events = eventDao.getPending(limit)
            Result.Success(events)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Update event upload status
     */
    suspend fun updateEventUploadStatus(ids: List<Long>, status: Int): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            eventDao.updateUploadStatus(ids, status)
            Result.Success(Unit)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    // ============================================================
    // Device State Operations
    // ============================================================

    /**
     * Insert a device state
     */
    suspend fun insertDeviceState(state: DeviceState): Result<Long> = withContext(Dispatchers.IO) {
        try {
            val id = deviceStateDao.insert(state)
            Result.Success(id)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Get latest device state
     */
    suspend fun getLatestDeviceState(userId: String): Result<DeviceState?> = withContext(Dispatchers.IO) {
        try {
            val state = deviceStateDao.getLatest(userId)
            Result.Success(state)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Get pending device states (ready for upload)
     */
    suspend fun getPendingDeviceStates(limit: Int = 100): Result<List<DeviceState>> = withContext(Dispatchers.IO) {
        try {
            val states = deviceStateDao.getPending(limit)
            Result.Success(states)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Update device state upload status
     */
    suspend fun updateDeviceStateUploadStatus(ids: List<Long>, status: Int): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            deviceStateDao.updateUploadStatus(ids, status)
            Result.Success(Unit)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    // ============================================================
    // Upload Queue Operations
    // ============================================================

    /**
     * Create an upload batch
     */
    suspend fun createUploadBatch(
        userId: String,
        dataType: String,
        itemCount: Int,
        priority: Int = 0,
        delayMs: Long = 0
    ): Result<String> = withContext(Dispatchers.IO) {
        try {
            val batchId = UUID.randomUUID().toString()
            val currentTime = System.currentTimeMillis()

            val item = UploadQueue(
                userId = userId,
                dataType = dataType,
                batchId = batchId,
                itemCount = itemCount,
                createdAt = currentTime,
                scheduledAt = currentTime + delayMs,
                priority = priority
            )

            uploadQueueDao.insert(item)
            Result.Success(batchId)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Get pending upload batches
     */
    suspend fun getPendingUploadBatches(limit: Int = 10): Result<List<UploadQueue>> = withContext(Dispatchers.IO) {
        try {
            val currentTime = System.currentTimeMillis()
            val batches = uploadQueueDao.getPending(currentTime, limit)
            Result.Success(batches)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Get upload batch by ID
     */
    suspend fun getUploadBatch(batchId: String): Result<UploadQueue?> = withContext(Dispatchers.IO) {
        try {
            val batch = uploadQueueDao.getByBatchId(batchId)
            Result.Success(batch)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Update upload batch status
     */
    suspend fun updateUploadBatchStatus(id: Long, status: Int): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            uploadQueueDao.updateUploadStatus(id, status)
            Result.Success(Unit)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Update upload batch with error
     */
    suspend fun updateUploadBatchWithError(
        id: Long,
        status: Int,
        errorMessage: String,
        retryDelayMs: Long
    ): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            val nextScheduledAt = System.currentTimeMillis() + retryDelayMs
            uploadQueueDao.updateUploadStatusWithError(id, status, errorMessage, nextScheduledAt)
            Result.Success(Unit)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Delete upload batch
     */
    suspend fun deleteUploadBatch(batchId: String): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            uploadQueueDao.deleteByBatchId(batchId)
            Result.Success(Unit)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    /**
     * Get count of pending items for each type
     */
    suspend fun getPendingCounts(): Result<Map<String, Int>> = withContext(Dispatchers.IO) {
        try {
            val counts = mapOf(
                "sensor_readings" to sensorReadingDao.getPendingCount(),
                "events" to eventDao.getPendingCount(),
                "device_states" to deviceStateDao.getPendingCount(),
                "upload_batches" to uploadQueueDao.getPendingCount()
            )
            Result.Success(counts)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    // ============================================================
    // Cleanup Operations
    // ============================================================

    /**
     * Clean up old uploaded data (older than specified days)
     */
    suspend fun cleanupOldData(daysToKeep: Int = 7): Result<Int> = withContext(Dispatchers.IO) {
        try {
            val cutoffTime = System.currentTimeMillis() - (daysToKeep * 24 * 60 * 60 * 1000L)

            val sensorCount = sensorReadingDao.deleteUploadedBefore(cutoffTime)
            val eventCount = eventDao.deleteUploadedBefore(cutoffTime)
            val deviceStateCount = deviceStateDao.deleteUploadedBefore(cutoffTime)
            val uploadQueueCount = uploadQueueDao.deleteUploadedBefore(cutoffTime)

            val totalCount = sensorCount + eventCount + deviceStateCount + uploadQueueCount
            Result.Success(totalCount)
        } catch (e: Exception) {
            Result.Error(e)
        }
    }
}
