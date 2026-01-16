package io.osrp.app.data.repository

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import io.osrp.app.data.Result
import io.osrp.app.data.local.OSRPDatabase
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
import kotlin.test.assertTrue

/**
 * Unit tests for DataRepository
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class DataRepositoryTest {

    private lateinit var database: OSRPDatabase
    private lateinit var repository: DataRepository
    private val testUserId = "test_user_001"

    @Before
    fun setup() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = Room.inMemoryDatabaseBuilder(context, OSRPDatabase::class.java)
            .allowMainThreadQueries()
            .build()

        repository = DataRepository(context, database)
    }

    @After
    fun teardown() {
        database.close()
    }

    // ============================================================
    // Sensor Reading Repository Tests
    // ============================================================

    @Test
    fun testInsertSensorReading() = runBlocking {
        val reading = SensorReading(
            userId = testUserId,
            sensorType = "accelerometer",
            timestamp = System.currentTimeMillis(),
            values = "{\"x\": 0.5, \"y\": 0.2, \"z\": 9.8}"
        )

        val result = repository.insertSensorReading(reading)

        assertTrue(result is Result.Success)
        assertTrue((result as Result.Success).data > 0)
    }

    @Test
    fun testInsertMultipleSensorReadings() = runBlocking {
        val readings = listOf(
            SensorReading(userId = testUserId, sensorType = "accelerometer", timestamp = 1000L, values = "{}"),
            SensorReading(userId = testUserId, sensorType = "gyroscope", timestamp = 2000L, values = "{}")
        )

        val result = repository.insertSensorReadings(readings)

        assertTrue(result is Result.Success)
        assertEquals(2, (result as Result.Success).data.size)
    }

    @Test
    fun testGetSensorReadingsByType() = runBlocking {
        val readings = listOf(
            SensorReading(userId = testUserId, sensorType = "accelerometer", timestamp = 1000L, values = "{}"),
            SensorReading(userId = testUserId, sensorType = "gyroscope", timestamp = 2000L, values = "{}"),
            SensorReading(userId = testUserId, sensorType = "accelerometer", timestamp = 3000L, values = "{}")
        )

        repository.insertSensorReadings(readings)

        val result = repository.getSensorReadingsByType(testUserId, "accelerometer")

        assertTrue(result is Result.Success)
        assertEquals(2, (result as Result.Success).data.size)
    }

    @Test
    fun testGetSensorReadingsByTimeRange() = runBlocking {
        val readings = listOf(
            SensorReading(userId = testUserId, sensorType = "accelerometer", timestamp = 1000L, values = "{}"),
            SensorReading(userId = testUserId, sensorType = "accelerometer", timestamp = 2000L, values = "{}"),
            SensorReading(userId = testUserId, sensorType = "accelerometer", timestamp = 3000L, values = "{}")
        )

        repository.insertSensorReadings(readings)

        val result = repository.getSensorReadingsByTimeRange(testUserId, 1500L, 2500L)

        assertTrue(result is Result.Success)
        assertEquals(1, (result as Result.Success).data.size)
        assertEquals(2000L, result.data[0].timestamp)
    }

    @Test
    fun testGetPendingSensorReadings() = runBlocking {
        val readings = listOf(
            SensorReading(userId = testUserId, sensorType = "test", timestamp = 1000L, values = "{}", uploadStatus = UploadStatus.PENDING),
            SensorReading(userId = testUserId, sensorType = "test", timestamp = 2000L, values = "{}", uploadStatus = UploadStatus.UPLOADED),
            SensorReading(userId = testUserId, sensorType = "test", timestamp = 3000L, values = "{}", uploadStatus = UploadStatus.PENDING)
        )

        repository.insertSensorReadings(readings)

        val result = repository.getPendingSensorReadings(limit = 10)

        assertTrue(result is Result.Success)
        assertEquals(2, (result as Result.Success).data.size)
    }

    @Test
    fun testUpdateSensorReadingUploadStatus() = runBlocking {
        val reading = SensorReading(
            userId = testUserId,
            sensorType = "test",
            timestamp = 1000L,
            values = "{}",
            uploadStatus = UploadStatus.PENDING
        )

        val insertResult = repository.insertSensorReading(reading)
        val id = (insertResult as Result.Success).data

        val updateResult = repository.updateSensorReadingUploadStatus(listOf(id), UploadStatus.UPLOADED)

        assertTrue(updateResult is Result.Success)
    }

    @Test
    fun testDeleteOldSensorReadings() = runBlocking {
        val cutoffTime = System.currentTimeMillis() - 1000
        val readings = listOf(
            SensorReading(userId = testUserId, sensorType = "test", timestamp = cutoffTime - 1000, values = "{}", uploadStatus = UploadStatus.UPLOADED),
            SensorReading(userId = testUserId, sensorType = "test", timestamp = cutoffTime + 1000, values = "{}", uploadStatus = UploadStatus.UPLOADED)
        )

        repository.insertSensorReadings(readings)

        val result = repository.deleteOldSensorReadings(cutoffTime)

        assertTrue(result is Result.Success)
        assertEquals(1, (result as Result.Success).data)
    }

    // ============================================================
    // Event Repository Tests
    // ============================================================

    @Test
    fun testInsertEvent() = runBlocking {
        val event = Event(
            userId = testUserId,
            eventType = "app_opened",
            timestamp = System.currentTimeMillis()
        )

        val result = repository.insertEvent(event)

        assertTrue(result is Result.Success)
        assertTrue((result as Result.Success).data > 0)
    }

    @Test
    fun testGetEventsByType() = runBlocking {
        val events = listOf(
            Event(userId = testUserId, eventType = "app_opened", timestamp = 1000L),
            Event(userId = testUserId, eventType = "button_clicked", timestamp = 2000L),
            Event(userId = testUserId, eventType = "app_opened", timestamp = 3000L)
        )

        repository.insertEvents(events)

        val result = repository.getEventsByType(testUserId, "app_opened")

        assertTrue(result is Result.Success)
        assertEquals(2, (result as Result.Success).data.size)
    }

    @Test
    fun testGetPendingEvents() = runBlocking {
        val events = listOf(
            Event(userId = testUserId, eventType = "test", timestamp = 1000L, uploadStatus = UploadStatus.PENDING),
            Event(userId = testUserId, eventType = "test", timestamp = 2000L, uploadStatus = UploadStatus.UPLOADED)
        )

        repository.insertEvents(events)

        val result = repository.getPendingEvents(limit = 10)

        assertTrue(result is Result.Success)
        assertEquals(1, (result as Result.Success).data.size)
    }

    // ============================================================
    // Device State Repository Tests
    // ============================================================

    @Test
    fun testInsertDeviceState() = runBlocking {
        val state = DeviceState(
            userId = testUserId,
            timestamp = System.currentTimeMillis(),
            batteryLevel = 85,
            isCharging = false,
            networkType = "wifi",
            availableStorage = 10000000000L,
            isScreenOn = true
        )

        val result = repository.insertDeviceState(state)

        assertTrue(result is Result.Success)
        assertTrue((result as Result.Success).data > 0)
    }

    @Test
    fun testGetLatestDeviceState() = runBlocking {
        val states = listOf(
            DeviceState(userId = testUserId, timestamp = 1000L, batteryLevel = 80, isCharging = false, networkType = "wifi", availableStorage = 1000L, isScreenOn = true),
            DeviceState(userId = testUserId, timestamp = 3000L, batteryLevel = 85, isCharging = false, networkType = "wifi", availableStorage = 1000L, isScreenOn = true),
            DeviceState(userId = testUserId, timestamp = 2000L, batteryLevel = 82, isCharging = false, networkType = "wifi", availableStorage = 1000L, isScreenOn = true)
        )

        for (state in states) {
            repository.insertDeviceState(state)
        }

        val result = repository.getLatestDeviceState(testUserId)

        assertTrue(result is Result.Success)
        assertNotNull((result as Result.Success).data)
        assertEquals(85, result.data!!.batteryLevel)
    }

    // ============================================================
    // Upload Queue Repository Tests
    // ============================================================

    @Test
    fun testCreateUploadBatch() = runBlocking {
        val result = repository.createUploadBatch(
            userId = testUserId,
            dataType = "sensor_readings",
            itemCount = 10,
            priority = 1
        )

        assertTrue(result is Result.Success)
        assertTrue((result as Result.Success).data.isNotEmpty())
    }

    @Test
    fun testGetPendingUploadBatches() = runBlocking {
        // Create multiple batches
        repository.createUploadBatch(testUserId, "sensor_readings", 10)
        repository.createUploadBatch(testUserId, "events", 5)

        val result = repository.getPendingUploadBatches(limit = 10)

        assertTrue(result is Result.Success)
        assertTrue((result as Result.Success).data.isNotEmpty())
    }

    @Test
    fun testGetUploadBatch() = runBlocking {
        val createResult = repository.createUploadBatch(testUserId, "sensor_readings", 10)
        val batchId = (createResult as Result.Success).data

        val getResult = repository.getUploadBatch(batchId)

        assertTrue(getResult is Result.Success)
        assertNotNull((getResult as Result.Success).data)
        assertEquals(batchId, getResult.data!!.batchId)
    }

    @Test
    fun testUpdateUploadBatchStatus() = runBlocking {
        val createResult = repository.createUploadBatch(testUserId, "sensor_readings", 10)
        val batchId = (createResult as Result.Success).data

        val getResult = repository.getUploadBatch(batchId)
        val id = (getResult as Result.Success).data!!.id

        val updateResult = repository.updateUploadBatchStatus(id, UploadStatus.UPLOADED)

        assertTrue(updateResult is Result.Success)
    }

    @Test
    fun testDeleteUploadBatch() = runBlocking {
        val createResult = repository.createUploadBatch(testUserId, "sensor_readings", 10)
        val batchId = (createResult as Result.Success).data

        val deleteResult = repository.deleteUploadBatch(batchId)

        assertTrue(deleteResult is Result.Success)

        val getResult = repository.getUploadBatch(batchId)
        assertTrue(getResult is Result.Success)
        assertEquals(null, (getResult as Result.Success).data)
    }

    @Test
    fun testGetPendingCounts() = runBlocking {
        // Insert data
        repository.insertSensorReading(
            SensorReading(userId = testUserId, sensorType = "test", timestamp = 1000L, values = "{}", uploadStatus = UploadStatus.PENDING)
        )
        repository.insertEvent(
            Event(userId = testUserId, eventType = "test", timestamp = 1000L, uploadStatus = UploadStatus.PENDING)
        )
        repository.insertDeviceState(
            DeviceState(userId = testUserId, timestamp = 1000L, batteryLevel = 80, isCharging = false, networkType = "wifi", availableStorage = 1000L, isScreenOn = true, uploadStatus = UploadStatus.PENDING)
        )
        repository.createUploadBatch(testUserId, "sensor_readings", 10)

        val result = repository.getPendingCounts()

        assertTrue(result is Result.Success)
        val counts = (result as Result.Success).data
        assertEquals(1, counts["sensor_readings"])
        assertEquals(1, counts["events"])
        assertEquals(1, counts["device_states"])
        assertEquals(1, counts["upload_batches"])
    }

    @Test
    fun testCleanupOldData() = runBlocking {
        val oldTime = System.currentTimeMillis() - (10 * 24 * 60 * 60 * 1000L) // 10 days ago
        val recentTime = System.currentTimeMillis() - (1 * 24 * 60 * 60 * 1000L) // 1 day ago

        // Insert old uploaded data
        repository.insertSensorReading(
            SensorReading(userId = testUserId, sensorType = "test", timestamp = oldTime, values = "{}", uploadStatus = UploadStatus.UPLOADED)
        )
        repository.insertEvent(
            Event(userId = testUserId, eventType = "test", timestamp = oldTime, uploadStatus = UploadStatus.UPLOADED)
        )

        // Insert recent uploaded data
        repository.insertSensorReading(
            SensorReading(userId = testUserId, sensorType = "test", timestamp = recentTime, values = "{}", uploadStatus = UploadStatus.UPLOADED)
        )

        val result = repository.cleanupOldData(daysToKeep = 7)

        assertTrue(result is Result.Success)
        // Should delete 2 old items (1 sensor reading + 1 event)
        assertEquals(2, (result as Result.Success).data)
    }
}
