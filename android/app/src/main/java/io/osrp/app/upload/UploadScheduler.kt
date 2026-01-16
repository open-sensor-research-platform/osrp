package io.osrp.app.upload

import android.content.Context
import androidx.work.*
import java.util.concurrent.TimeUnit

/**
 * Upload scheduler for managing data upload to AWS
 * Uses WorkManager for reliable background execution
 */
class UploadScheduler(private val context: Context) {

    private val workManager = WorkManager.getInstance(context)

    /**
     * Schedule immediate upload
     */
    fun scheduleImmediateUpload(
        wifiOnly: Boolean = true,
        requiresCharging: Boolean = false
    ) {
        val workRequest = UploadWorker.createWorkRequest(
            wifiOnly = wifiOnly,
            requiresCharging = requiresCharging
        )

        workManager.enqueueUniqueWork(
            UploadWorker.WORK_NAME,
            ExistingWorkPolicy.REPLACE,
            workRequest
        )
    }

    /**
     * Schedule periodic upload
     */
    fun schedulePeriodicUpload(
        intervalMinutes: Long = 15,
        wifiOnly: Boolean = true,
        requiresCharging: Boolean = false
    ) {
        val workRequest = UploadWorker.createPeriodicWorkRequest(
            intervalMinutes = intervalMinutes,
            wifiOnly = wifiOnly,
            requiresCharging = requiresCharging
        )

        workManager.enqueueUniquePeriodicWork(
            "${UploadWorker.WORK_NAME}_periodic",
            ExistingPeriodicWorkPolicy.UPDATE,
            workRequest
        )
    }

    /**
     * Cancel all upload work
     */
    fun cancelAllUploads() {
        workManager.cancelUniqueWork(UploadWorker.WORK_NAME)
        workManager.cancelUniqueWork("${UploadWorker.WORK_NAME}_periodic")
    }

    /**
     * Get upload work status
     */
    fun getUploadWorkInfo(): WorkInfo? {
        val workInfos = workManager.getWorkInfosForUniqueWork(UploadWorker.WORK_NAME).get()
        return workInfos.firstOrNull()
    }

    /**
     * Check if upload is running
     */
    fun isUploadRunning(): Boolean {
        val workInfo = getUploadWorkInfo()
        return workInfo?.state == WorkInfo.State.RUNNING
    }

    /**
     * Check if upload is enqueued
     */
    fun isUploadEnqueued(): Boolean {
        val workInfo = getUploadWorkInfo()
        return workInfo?.state == WorkInfo.State.ENQUEUED
    }

    companion object {
        /**
         * Default upload interval in minutes
         */
        const val DEFAULT_UPLOAD_INTERVAL_MINUTES = 15L

        /**
         * Minimum upload interval in minutes (WorkManager constraint)
         */
        const val MIN_UPLOAD_INTERVAL_MINUTES = 15L
    }
}
