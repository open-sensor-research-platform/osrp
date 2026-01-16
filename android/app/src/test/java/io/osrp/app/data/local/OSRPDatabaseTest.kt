package io.osrp.app.data.local

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import io.osrp.app.data.local.entity.*
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Unit tests for OSRP Database
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class OSRPDatabaseTest {

    private lateinit var database: OSRPDatabase
    private val testUserId = "test_user_001"

    @Before
    fun setup() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = Room.inMemoryDatabaseBuilder(context, OSRPDatabase::class.java)
            .allowMainThreadQueries()
            .build()
    }

    @After
    fun teardown() {
        database.close()
    }

    // ============================================================
    // Sensor Reading Tests
    // ============================================================

    @Test
    fun testInsertAndGetSensorReading() = runBlocking {
        val reading = SensorReading(
            userId = testUserId,
            sensorType = "accelerometer",
            timestamp = System.currentTimeMillis(),
            values = "{\"x\": 0.5, \"y\": 0.2, \"z\": 9.8}",
            metadata = "{\"device_id\": \"abc123\"}"
        )

        val id = database.sensorReadingDao().insert(reading)
        assertTrue(id > 0)

        val readings = database.sensorReadingDao().getAllByUser(testUserId)
        assertEquals(1, readings.size)
        assertEquals("accelerometer", readings[0].sensorType)
    }

    @Test
    fun testInsertMultipleSensorReadings() = runBlocking {
        val readings = listOf(
            SensorReading(
                userId = testUserId,
                sensorType = "accelerometer",
                timestamp = System.currentTimeMillis(),
                values = "{\"x\": 0.5}"
            ),
            SensorReading(
                userId = testUserId,
                sensorType = "gyroscope",
                timestamp = System.currentTimeMillis(),
                values = "{\"x\": 0.1}"
            )
        )

        val ids = database.sensorReadingDao().insertAll(readings)
        assertEquals(2, ids.size)

        val allReadings = database.sensorReadingDao().getAllByUser(testUserId)
        assertEquals(2, allReadings.size)
    }

    @Test
    fun testGetSensorReadingsByType() = runBlocking {
        val readings = listOf(
            SensorReading(userId = testUserId, sensorType = "accelerometer", timestamp = 1000L, values = "{}"),
            SensorReading(userId = testUserId, sensorType = "gyroscope", timestamp = 2000L, values = "{}"),
            SensorReading(userId = testUserId, sensorType = "accelerometer", timestamp = 3000L, values = "{}")
        )

        database.sensorReadingDao().insertAll(readings)

        val accelReadings = database.sensorReadingDao().getByType(testUserId, "accelerometer")
        assertEquals(2, accelReadings.size)

        val gyroReadings = database.sensorReadingDao().getByType(testUserId, "gyroscope")
        assertEquals(1, gyroReadings.size)
    }

    @Test
    fun testGetSensorReadingsByTimeRange() = runBlocking {
        val readings = listOf(
            SensorReading(userId = testUserId, sensorType = "accelerometer", timestamp = 1000L, values = "{}"),
            SensorReading(userId = testUserId, sensorType = "accelerometer", timestamp = 2000L, values = "{}"),
            SensorReading(userId = testUserId, sensorType = "accelerometer", timestamp = 3000L, values = "{}")
        )

        database.sensorReadingDao().insertAll(readings)

        val rangeReadings = database.sensorReadingDao().getByTimeRange(testUserId, 1500L, 2500L)
        assertEquals(1, rangeReadings.size)
        assertEquals(2000L, rangeReadings[0].timestamp)
    }

    @Test
    fun testGetPendingSensorReadings() = runBlocking {
        val readings = listOf(
            SensorReading(userId = testUserId, sensorType = "accelerometer", timestamp = 1000L, values = "{}", uploadStatus = UploadStatus.PENDING),
            SensorReading(userId = testUserId, sensorType = "accelerometer", timestamp = 2000L, values = "{}", uploadStatus = UploadStatus.UPLOADED),
            SensorReading(userId = testUserId, sensorType = "accelerometer", timestamp = 3000L, values = "{}", uploadStatus = UploadStatus.PENDING)
        )

        database.sensorReadingDao().insertAll(readings)

        val pendingReadings = database.sensorReadingDao().getPending(limit = 10)
        assertEquals(2, pendingReadings.size)
    }

    @Test
    fun testUpdateSensorReadingUploadStatus() = runBlocking {
        val reading = SensorReading(
            userId = testUserId,
            sensorType = "accelerometer",
            timestamp = 1000L,
            values = "{}",
            uploadStatus = UploadStatus.PENDING
        )

        val id = database.sensorReadingDao().insert(reading)

        database.sensorReadingDao().updateUploadStatus(listOf(id), UploadStatus.UPLOADED)

        val updated = database.sensorReadingDao().getAllByUser(testUserId)
        assertEquals(UploadStatus.UPLOADED, updated[0].uploadStatus)
    }

    @Test
    fun testDeleteUploadedSensorReadings() = runBlocking {
        val cutoffTime = System.currentTimeMillis() - 1000
        val readings = listOf(
            SensorReading(userId = testUserId, sensorType = "accelerometer", timestamp = cutoffTime - 1000, values = "{}", uploadStatus = UploadStatus.UPLOADED),
            SensorReading(userId = testUserId, sensorType = "accelerometer", timestamp = cutoffTime + 1000, values = "{}", uploadStatus = UploadStatus.UPLOADED)
        )

        database.sensorReadingDao().insertAll(readings)

        val deletedCount = database.sensorReadingDao().deleteUploadedBefore(cutoffTime)
        assertEquals(1, deletedCount)

        val remaining = database.sensorReadingDao().getAllByUser(testUserId)
        assertEquals(1, remaining.size)
    }

    // ============================================================
    // Event Tests
    // ============================================================

    @Test
    fun testInsertAndGetEvent() = runBlocking {
        val event = Event(
            userId = testUserId,
            eventType = "app_opened",
            timestamp = System.currentTimeMillis(),
            properties = "{\"screen\": \"home\"}"
        )

        val id = database.eventDao().insert(event)
        assertTrue(id > 0)

        val events = database.eventDao().getAllByUser(testUserId)
        assertEquals(1, events.size)
        assertEquals("app_opened", events[0].eventType)
    }

    @Test
    fun testGetEventsByType() = runBlocking {
        val events = listOf(
            Event(userId = testUserId, eventType = "app_opened", timestamp = 1000L),
            Event(userId = testUserId, eventType = "button_clicked", timestamp = 2000L),
            Event(userId = testUserId, eventType = "app_opened", timestamp = 3000L)
        )

        database.eventDao().insertAll(events)

        val appOpenedEvents = database.eventDao().getByType(testUserId, "app_opened")
        assertEquals(2, appOpenedEvents.size)
    }

    @Test
    fun testGetPendingEvents() = runBlocking {
        val events = listOf(
            Event(userId = testUserId, eventType = "test", timestamp = 1000L, uploadStatus = UploadStatus.PENDING),
            Event(userId = testUserId, eventType = "test", timestamp = 2000L, uploadStatus = UploadStatus.UPLOADED),
            Event(userId = testUserId, eventType = "test", timestamp = 3000L, uploadStatus = UploadStatus.PENDING)
        )

        database.eventDao().insertAll(events)

        val pendingEvents = database.eventDao().getPending(limit = 10)
        assertEquals(2, pendingEvents.size)
    }

    // ============================================================
    // Device State Tests
    // ============================================================

    @Test
    fun testInsertAndGetDeviceState() = runBlocking {
        val state = DeviceState(
            userId = testUserId,
            timestamp = System.currentTimeMillis(),
            batteryLevel = 85,
            isCharging = false,
            networkType = "wifi",
            availableStorage = 10000000000L,
            isScreenOn = true
        )

        val id = database.deviceStateDao().insert(state)
        assertTrue(id > 0)

        val states = database.deviceStateDao().getAllByUser(testUserId)
        assertEquals(1, states.size)
        assertEquals(85, states[0].batteryLevel)
    }

    @Test
    fun testGetLatestDeviceState() = runBlocking {
        val states = listOf(
            DeviceState(userId = testUserId, timestamp = 1000L, batteryLevel = 80, isCharging = false, networkType = "wifi", availableStorage = 1000L, isScreenOn = true),
            DeviceState(userId = testUserId, timestamp = 3000L, batteryLevel = 85, isCharging = false, networkType = "wifi", availableStorage = 1000L, isScreenOn = true),
            DeviceState(userId = testUserId, timestamp = 2000L, batteryLevel = 82, isCharging = false, networkType = "wifi", availableStorage = 1000L, isScreenOn = true)
        )

        database.deviceStateDao().insertAll(states)

        val latest = database.deviceStateDao().getLatest(testUserId)
        assertNotNull(latest)
        assertEquals(85, latest.batteryLevel)
        assertEquals(3000L, latest.timestamp)
    }

    // ============================================================
    // Upload Queue Tests
    // ============================================================

    @Test
    fun testInsertAndGetUploadQueue() = runBlocking {
        val currentTime = System.currentTimeMillis()
        val item = UploadQueue(
            userId = testUserId,
            dataType = "sensor_readings",
            batchId = "batch_001",
            itemCount = 10,
            createdAt = currentTime,
            scheduledAt = currentTime,
            priority = 1
        )

        val id = database.uploadQueueDao().insert(item)
        assertTrue(id > 0)

        val items = database.uploadQueueDao().getAll()
        assertEquals(1, items.size)
        assertEquals("batch_001", items[0].batchId)
    }

    @Test
    fun testGetPendingUploadQueue() = runBlocking {
        val currentTime = System.currentTimeMillis()
        val items = listOf(
            UploadQueue(userId = testUserId, dataType = "sensor_readings", batchId = "batch_001", itemCount = 10, createdAt = currentTime, scheduledAt = currentTime - 1000, uploadStatus = UploadStatus.PENDING),
            UploadQueue(userId = testUserId, dataType = "events", batchId = "batch_002", itemCount = 5, createdAt = currentTime, scheduledAt = currentTime + 10000, uploadStatus = UploadStatus.PENDING),
            UploadQueue(userId = testUserId, dataType = "device_states", batchId = "batch_003", itemCount = 3, createdAt = currentTime, scheduledAt = currentTime - 500, uploadStatus = UploadStatus.UPLOADED)
        )

        database.uploadQueueDao().insertAll(items)

        val pendingItems = database.uploadQueueDao().getPending(currentTime, limit = 10)
        assertEquals(1, pendingItems.size)
        assertEquals("batch_001", pendingItems[0].batchId)
    }

    @Test
    fun testGetUploadQueueByBatchId() = runBlocking {
        val currentTime = System.currentTimeMillis()
        val item = UploadQueue(
            userId = testUserId,
            dataType = "sensor_readings",
            batchId = "batch_unique",
            itemCount = 10,
            createdAt = currentTime,
            scheduledAt = currentTime
        )

        database.uploadQueueDao().insert(item)

        val found = database.uploadQueueDao().getByBatchId("batch_unique")
        assertNotNull(found)
        assertEquals("batch_unique", found.batchId)

        val notFound = database.uploadQueueDao().getByBatchId("nonexistent")
        assertNull(notFound)
    }

    @Test
    fun testDeleteUploadQueueByBatchId() = runBlocking {
        val currentTime = System.currentTimeMillis()
        val items = listOf(
            UploadQueue(userId = testUserId, dataType = "sensor_readings", batchId = "batch_001", itemCount = 10, createdAt = currentTime, scheduledAt = currentTime),
            UploadQueue(userId = testUserId, dataType = "events", batchId = "batch_002", itemCount = 5, createdAt = currentTime, scheduledAt = currentTime)
        )

        database.uploadQueueDao().insertAll(items)

        database.uploadQueueDao().deleteByBatchId("batch_001")

        val remaining = database.uploadQueueDao().getAll()
        assertEquals(1, remaining.size)
        assertEquals("batch_002", remaining[0].batchId)
    }

    @Test
    fun testGetPendingCountsForAllTables() = runBlocking {
        // Insert sensor readings
        database.sensorReadingDao().insertAll(listOf(
            SensorReading(userId = testUserId, sensorType = "test", timestamp = 1000L, values = "{}", uploadStatus = UploadStatus.PENDING),
            SensorReading(userId = testUserId, sensorType = "test", timestamp = 2000L, values = "{}", uploadStatus = UploadStatus.UPLOADED)
        ))

        // Insert events
        database.eventDao().insertAll(listOf(
            Event(userId = testUserId, eventType = "test", timestamp = 1000L, uploadStatus = UploadStatus.PENDING),
            Event(userId = testUserId, eventType = "test", timestamp = 2000L, uploadStatus = UploadStatus.PENDING),
            Event(userId = testUserId, eventType = "test", timestamp = 3000L, uploadStatus = UploadStatus.UPLOADED)
        ))

        // Insert device states
        database.deviceStateDao().insert(
            DeviceState(userId = testUserId, timestamp = 1000L, batteryLevel = 80, isCharging = false, networkType = "wifi", availableStorage = 1000L, isScreenOn = true, uploadStatus = UploadStatus.PENDING)
        )

        // Verify counts
        assertEquals(1, database.sensorReadingDao().getPendingCount())
        assertEquals(2, database.eventDao().getPendingCount())
        assertEquals(1, database.deviceStateDao().getPendingCount())
    }
}
