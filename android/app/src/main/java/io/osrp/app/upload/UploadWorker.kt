package io.osrp.app.upload

import android.content.Context
import androidx.work.*
import com.google.gson.Gson
import io.osrp.app.data.local.entity.UploadStatus
import io.osrp.app.data.repository.AuthRepository
import io.osrp.app.data.repository.DataRepository
import io.osrp.app.data.remote.OSRPApiService
import io.osrp.app.data.remote.RetrofitClient
import io.osrp.app.data.remote.SensorDataRequest
import io.osrp.app.util.workDataOf
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.concurrent.TimeUnit
import io.osrp.app.data.remote.SensorReading as ApiSensorReading

/**
 * WorkManager worker for uploading sensor data to AWS
 * Implements retry logic with exponential backoff
 */
class UploadWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    private val dataRepository = DataRepository(context)
    private val authRepository = AuthRepository(context)
    private val apiService: OSRPApiService = RetrofitClient.apiService
    private val gson = Gson()

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        try {
            // Check if user is logged in
            if (!authRepository.isLoggedIn()) {
                return@withContext Result.failure(
                    workDataOf("error" to "User not logged in")
                )
            }

            // Get authorization token
            val authHeader = authRepository.getAuthorizationHeader()
            if (authHeader == null) {
                return@withContext Result.failure(
                    workDataOf("error" to "Failed to get authorization token")
                )
            }

            // Get pending sensor readings from database
            val pendingReadings = dataRepository.getPendingSensorReadings(limit = 100)

            if (pendingReadings !is io.osrp.app.data.Result.Success || pendingReadings.data.isEmpty()) {
                // No data to upload
                return@withContext Result.success(
                    workDataOf("message" to "No data to upload")
                )
            }

            val readings = pendingReadings.data

            // Group readings by sensor type
            val groupedReadings = readings.groupBy { it.sensorType }

            var totalUploaded = 0
            var totalFailed = 0

            // Upload each sensor type separately
            for ((sensorType, sensorReadings) in groupedReadings) {
                try {
                    // Convert to API format
                    val apiReadings = sensorReadings.map { reading ->
                        val valuesMap = gson.fromJson(
                            reading.values,
                            Map::class.java
                        ) as Map<String, Float>

                        val metadata = reading.metadata?.let {
                            gson.fromJson(it, Map::class.java) as? Map<String, Any>
                        } ?: emptyMap()

                        val accuracy = (metadata["accuracy"] as? Number)?.toInt() ?: 0

                        ApiSensorReading(
                            timestamp = reading.timestamp,
                            data = valuesMap,
                            accuracy = accuracy
                        )
                    }

                    // Get study code from user email (for now, use a default)
                    // TODO: Store study code in AuthRepository
                    val studyCode = "default-study"

                    // Create upload request
                    val uploadRequest = SensorDataRequest(
                        sensorType = sensorType,
                        readings = apiReadings,
                        studyCode = studyCode
                    )

                    // Upload to AWS
                    val response = apiService.uploadSensorData(authHeader, uploadRequest)

                    if (response.isSuccessful) {
                        // Mark readings as uploaded
                        val readingIds = sensorReadings.map { it.id }
                        dataRepository.updateSensorReadingUploadStatus(
                            readingIds,
                            UploadStatus.UPLOADED
                        )

                        totalUploaded += sensorReadings.size

                        // Delete old uploaded data (older than 7 days)
                        val sevenDaysAgo = System.currentTimeMillis() - (7 * 24 * 60 * 60 * 1000L)
                        dataRepository.deleteOldSensorReadings(sevenDaysAgo)

                    } else {
                        // Mark as failed
                        val readingIds = sensorReadings.map { it.id }
                        dataRepository.updateSensorReadingUploadStatus(
                            readingIds,
                            UploadStatus.FAILED
                        )

                        totalFailed += sensorReadings.size
                    }

                } catch (e: Exception) {
                    // Mark as failed
                    val readingIds = sensorReadings.map { it.id }
                    dataRepository.updateSensorReadingUploadStatus(
                        readingIds,
                        UploadStatus.FAILED
                    )

                    totalFailed += sensorReadings.size
                }
            }

            // Return success or retry based on results
            return@withContext if (totalFailed > 0 && totalUploaded == 0) {
                // All uploads failed - retry
                Result.retry()
            } else if (totalFailed > 0) {
                // Some uploads failed - success but with warning
                Result.success(
                    workDataOf(
                        "uploaded" to totalUploaded,
                        "failed" to totalFailed,
                        "message" to "Partial upload success"
                    )
                )
            } else {
                // All uploads succeeded
                Result.success(
                    workDataOf(
                        "uploaded" to totalUploaded,
                        "message" to "Upload successful"
                    )
                )
            }

        } catch (e: Exception) {
            // Unexpected error - retry
            return@withContext Result.retry()
        }
    }

    companion object {
        const val WORK_NAME = "sensor_data_upload"

        /**
         * Create work request with constraints
         */
        fun createWorkRequest(
            wifiOnly: Boolean = true,
            requiresCharging: Boolean = false
        ): OneTimeWorkRequest {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(
                    if (wifiOnly) NetworkType.UNMETERED else NetworkType.CONNECTED
                )
                .setRequiresCharging(requiresCharging)
                .build()

            return OneTimeWorkRequestBuilder<UploadWorker>()
                .setConstraints(constraints)
                .setBackoffCriteria(
                    BackoffPolicy.EXPONENTIAL,
                    OneTimeWorkRequest.MIN_BACKOFF_MILLIS,
                    TimeUnit.MILLISECONDS
                )
                .build()
        }

        /**
         * Create periodic work request
         */
        fun createPeriodicWorkRequest(
            intervalMinutes: Long = 15,
            wifiOnly: Boolean = true,
            requiresCharging: Boolean = false
        ): PeriodicWorkRequest {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(
                    if (wifiOnly) NetworkType.UNMETERED else NetworkType.CONNECTED
                )
                .setRequiresCharging(requiresCharging)
                .build()

            return PeriodicWorkRequestBuilder<UploadWorker>(
                intervalMinutes,
                TimeUnit.MINUTES
            )
                .setConstraints(constraints)
                .setBackoffCriteria(
                    BackoffPolicy.EXPONENTIAL,
                    PeriodicWorkRequest.MIN_BACKOFF_MILLIS,
                    TimeUnit.MILLISECONDS
                )
                .build()
        }
    }
}
