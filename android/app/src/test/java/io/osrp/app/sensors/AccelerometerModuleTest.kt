package io.osrp.app.sensors

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorManager
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import io.osrp.app.data.local.OSRPDatabase
import io.osrp.app.data.repository.DataRepository
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowSensorManager
import kotlin.test.*

/**
 * Unit tests for AccelerometerModule
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class AccelerometerModuleTest {

    private lateinit var context: Context
    private lateinit var database: OSRPDatabase
    private lateinit var dataRepository: DataRepository
    private lateinit var accelerometerModule: AccelerometerModule
    private lateinit var sensorManager: SensorManager
    private lateinit var shadowSensorManager: ShadowSensorManager

    private val testUserId = "test_user_001"
    private val samplingRateHz = 5

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()

        // Setup in-memory database
        database = Room.inMemoryDatabaseBuilder(context, OSRPDatabase::class.java)
            .allowMainThreadQueries()
            .build()

        dataRepository = DataRepository(context, database)

        // Setup sensor manager shadow
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        shadowSensorManager = shadowOf(sensorManager)

        // Add accelerometer sensor to shadow
        val accelerometer = Sensor::class.java.getDeclaredConstructor().apply {
            isAccessible = true
        }.newInstance()

        shadowSensorManager.addSensor(Sensor.TYPE_ACCELEROMETER, accelerometer)

        // Create accelerometer module
        accelerometerModule = AccelerometerModule(
            context = context,
            dataRepository = dataRepository,
            userId = testUserId,
            samplingRateHz = samplingRateHz
        )
    }

    @After
    fun teardown() {
        accelerometerModule.cleanup()
        database.close()
    }

    @Test
    fun testSensorTypeIsAccelerometer() {
        assertEquals("accelerometer", accelerometerModule.sensorType)
    }

    @Test
    fun testSamplingRateIsConfigurable() {
        assertEquals(samplingRateHz, accelerometerModule.samplingRateHz)
    }

    @Test
    fun testSensorIsAvailable() {
        assertTrue(accelerometerModule.isSensorAvailable())
    }

    @Test
    fun testSensorIsNotCollectingInitially() {
        assertFalse(accelerometerModule.isCollecting)
    }

    @Test
    fun testStartCollection() = runBlocking {
        assertFalse(accelerometerModule.isCollecting)

        accelerometerModule.startCollection()

        assertTrue(accelerometerModule.isCollecting)
    }

    @Test
    fun testStopCollection() = runBlocking {
        accelerometerModule.startCollection()
        assertTrue(accelerometerModule.isCollecting)

        accelerometerModule.stopCollection()

        assertFalse(accelerometerModule.isCollecting)
    }

    @Test
    fun testGetSensorStatus() = runBlocking {
        val statusBefore = accelerometerModule.getSensorStatus()

        assertEquals("accelerometer", statusBefore.sensorType)
        assertTrue(statusBefore.isAvailable)
        assertFalse(statusBefore.isCollecting)
        assertEquals(samplingRateHz, statusBefore.samplingRateHz)
        assertEquals(0L, statusBefore.totalReadingsCollected)
        assertNull(statusBefore.lastReadingTimestamp)

        accelerometerModule.startCollection()

        val statusAfter = accelerometerModule.getSensorStatus()
        assertTrue(statusAfter.isCollecting)
    }

    @Test
    fun testCannotStartCollectionTwice() = runBlocking {
        accelerometerModule.startCollection()
        assertTrue(accelerometerModule.isCollecting)

        // Starting again should be a no-op
        accelerometerModule.startCollection()
        assertTrue(accelerometerModule.isCollecting)
    }

    @Test
    fun testStopCollectionWhenNotCollecting() = runBlocking {
        assertFalse(accelerometerModule.isCollecting)

        // Stopping when not collecting should be a no-op
        accelerometerModule.stopCollection()

        assertFalse(accelerometerModule.isCollecting)
    }

    @Test
    fun testSensorReadingsFlow() = runBlocking {
        val readings = mutableListOf<SensorData>()

        // Collect readings from flow
        val job = kotlinx.coroutines.launch {
            accelerometerModule.getSensorReadingsFlow().collect { reading ->
                readings.add(reading)
            }
        }

        // Start collection
        accelerometerModule.startCollection()

        // Wait briefly (in real scenario, sensor events would be triggered)
        delay(100)

        // Stop collection
        accelerometerModule.stopCollection()

        job.cancel()

        // Note: In Robolectric, actual sensor events won't be triggered
        // This test verifies the flow is set up correctly
        // Real sensor data collection should be tested on device
    }

    @Test
    fun testCleanup() = runBlocking {
        accelerometerModule.startCollection()
        assertTrue(accelerometerModule.isCollecting)

        accelerometerModule.cleanup()

        assertFalse(accelerometerModule.isCollecting)
    }

    @Test
    fun testSensorModuleConfiguration() {
        val customModule = AccelerometerModule(
            context = context,
            dataRepository = dataRepository,
            userId = "custom_user",
            samplingRateHz = 10
        )

        assertEquals("accelerometer", customModule.sensorType)
        assertEquals(10, customModule.samplingRateHz)
        assertFalse(customModule.isCollecting)

        customModule.cleanup()
    }
}
