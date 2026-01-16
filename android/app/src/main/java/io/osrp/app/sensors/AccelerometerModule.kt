package io.osrp.app.sensors

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import com.google.gson.Gson
import io.osrp.app.data.local.entity.SensorReading
import io.osrp.app.data.repository.DataRepository
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlin.math.roundToInt

/**
 * Accelerometer sensor module
 * Collects 3-axis accelerometer data (x, y, z in m/s²)
 */
class AccelerometerModule(
    private val context: Context,
    private val dataRepository: DataRepository,
    private val userId: String,
    override val samplingRateHz: Int = 5  // Default: 5 Hz
) : BaseSensorModule, SensorEventListener {

    override val sensorType: String = "accelerometer"

    private val sensorManager: SensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager

    private val accelerometer: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

    private val gson = Gson()

    // Coroutine scope for sensor operations
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    // Shared flow for real-time sensor readings
    private val _sensorReadingsFlow = MutableSharedFlow<SensorData>(replay = 0)

    // State tracking
    override var isCollecting: Boolean = false
        private set

    private var totalReadingsCollected: Long = 0
    private var lastReadingTimestamp: Long? = null

    // Batching configuration
    private val batchSize = 50  // Batch readings before saving to database
    private val readingsBatch = mutableListOf<SensorReading>()
    private var lastBatchSaveTime = System.currentTimeMillis()
    private val batchSaveIntervalMs = 10000L  // Save batch every 10 seconds

    // Sampling rate control
    private var lastSampleTime = 0L
    private val sampleIntervalNanos = (1_000_000_000.0 / samplingRateHz).toLong()

    override suspend fun startCollection() = withContext(Dispatchers.Main) {
        if (isCollecting) {
            return@withContext
        }

        if (!isSensorAvailable()) {
            throw IllegalStateException("Accelerometer sensor not available on this device")
        }

        // Register sensor listener
        val samplingPeriodUs = (1_000_000.0 / samplingRateHz).roundToInt()
        val success = sensorManager.registerListener(
            this@AccelerometerModule,
            accelerometer,
            samplingPeriodUs,
            samplingPeriodUs / 2  // Max report latency (half of sampling period)
        )

        if (success) {
            isCollecting = true
            totalReadingsCollected = 0
            lastSampleTime = 0L

            // Start periodic batch save job
            startBatchSaveJob()
        } else {
            throw IllegalStateException("Failed to register accelerometer sensor listener")
        }
    }

    override suspend fun stopCollection() = withContext(Dispatchers.Main) {
        if (!isCollecting) {
            return@withContext
        }

        // Unregister sensor listener
        sensorManager.unregisterListener(this@AccelerometerModule)
        isCollecting = false

        // Save any remaining readings in batch
        saveBatch()

        // Cancel batch save job
        scope.coroutineContext.cancelChildren()
    }

    override fun isSensorAvailable(): Boolean {
        return accelerometer != null
    }

    override fun getSensorStatus(): SensorStatus {
        return SensorStatus(
            sensorType = sensorType,
            isAvailable = isSensorAvailable(),
            isCollecting = isCollecting,
            samplingRateHz = samplingRateHz,
            totalReadingsCollected = totalReadingsCollected,
            lastReadingTimestamp = lastReadingTimestamp
        )
    }

    override fun getSensorReadingsFlow(): Flow<SensorData> {
        return _sensorReadingsFlow.asSharedFlow()
    }

    // SensorEventListener implementation

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || event.sensor.type != Sensor.TYPE_ACCELEROMETER) {
            return
        }

        // Rate limiting - sample at configured rate
        val currentTime = System.nanoTime()
        if (currentTime - lastSampleTime < sampleIntervalNanos) {
            return
        }
        lastSampleTime = currentTime

        val timestamp = System.currentTimeMillis()
        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]
        val accuracy = event.accuracy

        // Create sensor data
        val sensorData = SensorData(
            sensorType = sensorType,
            timestamp = timestamp,
            values = mapOf("x" to x, "y" to y, "z" to z),
            accuracy = accuracy
        )

        // Emit to flow for real-time monitoring
        scope.launch {
            _sensorReadingsFlow.emit(sensorData)
        }

        // Create sensor reading for database
        val valuesJson = gson.toJson(mapOf("x" to x, "y" to y, "z" to z))
        val metadataJson = gson.toJson(mapOf(
            "accuracy" to accuracy,
            "sampling_rate_hz" to samplingRateHz
        ))

        val reading = SensorReading(
            userId = userId,
            sensorType = sensorType,
            timestamp = timestamp,
            values = valuesJson,
            metadata = metadataJson
        )

        // Add to batch
        synchronized(readingsBatch) {
            readingsBatch.add(reading)
            totalReadingsCollected++
            lastReadingTimestamp = timestamp

            // Save batch if size threshold reached
            if (readingsBatch.size >= batchSize) {
                scope.launch {
                    saveBatch()
                }
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Log accuracy changes if needed
    }

    /**
     * Save current batch of readings to database
     */
    private suspend fun saveBatch() {
        val readingsToSave: List<SensorReading>

        synchronized(readingsBatch) {
            if (readingsBatch.isEmpty()) {
                return
            }

            readingsToSave = readingsBatch.toList()
            readingsBatch.clear()
            lastBatchSaveTime = System.currentTimeMillis()
        }

        // Save to database
        withContext(Dispatchers.IO) {
            dataRepository.insertSensorReadings(readingsToSave)
        }
    }

    /**
     * Start periodic batch save job
     */
    private fun startBatchSaveJob() {
        scope.launch {
            while (isActive && isCollecting) {
                delay(batchSaveIntervalMs)

                // Check if it's time to save batch
                val timeSinceLastSave = System.currentTimeMillis() - lastBatchSaveTime
                if (timeSinceLastSave >= batchSaveIntervalMs) {
                    saveBatch()
                }
            }
        }
    }

    /**
     * Clean up resources
     */
    fun cleanup() {
        scope.cancel()
        if (isCollecting) {
            runBlocking {
                stopCollection()
            }
        }
    }
}
