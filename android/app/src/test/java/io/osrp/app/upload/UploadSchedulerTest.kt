package io.osrp.app.upload

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.testing.WorkManagerTestInitHelper
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Unit tests for UploadScheduler
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class UploadSchedulerTest {

    private lateinit var context: Context
    private lateinit var uploadScheduler: UploadScheduler
    private lateinit var workManager: WorkManager

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()

        // Initialize WorkManager for testing
        WorkManagerTestInitHelper.initializeTestWorkManager(context)
        workManager = WorkManager.getInstance(context)

        uploadScheduler = UploadScheduler(context)
    }

    @Test
    fun testScheduleImmediateUpload() {
        uploadScheduler.scheduleImmediateUpload(wifiOnly = true, requiresCharging = false)

        // Verify work is enqueued
        val workInfos = workManager.getWorkInfosForUniqueWork(UploadWorker.WORK_NAME).get()
        assertTrue(workInfos.isNotEmpty())

        val workInfo = workInfos.first()
        assertEquals(WorkInfo.State.ENQUEUED, workInfo.state)
    }

    @Test
    fun testScheduleImmediateUploadWithCharging() {
        uploadScheduler.scheduleImmediateUpload(wifiOnly = false, requiresCharging = true)

        val workInfos = workManager.getWorkInfosForUniqueWork(UploadWorker.WORK_NAME).get()
        assertTrue(workInfos.isNotEmpty())
    }

    @Test
    fun testSchedulePeriodicUpload() {
        uploadScheduler.schedulePeriodicUpload(
            intervalMinutes = 15,
            wifiOnly = true,
            requiresCharging = false
        )

        // Verify periodic work is enqueued
        val workInfos = workManager.getWorkInfosForUniqueWork(
            "${UploadWorker.WORK_NAME}_periodic"
        ).get()
        assertTrue(workInfos.isNotEmpty())
    }

    @Test
    fun testCancelAllUploads() {
        // Schedule some work
        uploadScheduler.scheduleImmediateUpload()
        uploadScheduler.schedulePeriodicUpload()

        // Cancel all
        uploadScheduler.cancelAllUploads()

        // Verify work is cancelled
        val immediateWorkInfos = workManager.getWorkInfosForUniqueWork(UploadWorker.WORK_NAME).get()
        val periodicWorkInfos = workManager.getWorkInfosForUniqueWork(
            "${UploadWorker.WORK_NAME}_periodic"
        ).get()

        // After cancellation, work should be cancelled or not exist
        assertTrue(
            immediateWorkInfos.isEmpty() ||
            immediateWorkInfos.all { it.state == WorkInfo.State.CANCELLED }
        )
        assertTrue(
            periodicWorkInfos.isEmpty() ||
            periodicWorkInfos.all { it.state == WorkInfo.State.CANCELLED }
        )
    }

    @Test
    fun testGetUploadWorkInfo() {
        uploadScheduler.scheduleImmediateUpload()

        val workInfo = uploadScheduler.getUploadWorkInfo()
        assertNotNull(workInfo)
        assertEquals(WorkInfo.State.ENQUEUED, workInfo.state)
    }

    @Test
    fun testIsUploadEnqueued() {
        assertFalse(uploadScheduler.isUploadEnqueued())

        uploadScheduler.scheduleImmediateUpload()

        assertTrue(uploadScheduler.isUploadEnqueued())
    }

    @Test
    fun testIsUploadRunning() {
        assertFalse(uploadScheduler.isUploadRunning())

        uploadScheduler.scheduleImmediateUpload()

        // Work is enqueued but not running yet
        assertFalse(uploadScheduler.isUploadRunning())
    }

    @Test
    fun testDefaultUploadInterval() {
        assertEquals(15L, UploadScheduler.DEFAULT_UPLOAD_INTERVAL_MINUTES)
    }

    @Test
    fun testMinUploadInterval() {
        assertEquals(15L, UploadScheduler.MIN_UPLOAD_INTERVAL_MINUTES)
    }

    @Test
    fun testScheduleImmediateUploadReplacesExisting() {
        // Schedule first upload
        uploadScheduler.scheduleImmediateUpload(wifiOnly = true)

        // Schedule second upload (should replace)
        uploadScheduler.scheduleImmediateUpload(wifiOnly = false)

        // Should only have one work item
        val workInfos = workManager.getWorkInfosForUniqueWork(UploadWorker.WORK_NAME).get()
        assertEquals(1, workInfos.size)
    }

    @Test
    fun testSchedulePeriodicUploadUpdatesExisting() {
        // Schedule first periodic upload
        uploadScheduler.schedulePeriodicUpload(intervalMinutes = 15)

        // Schedule second periodic upload (should update)
        uploadScheduler.schedulePeriodicUpload(intervalMinutes = 30)

        // Should only have one work item
        val workInfos = workManager.getWorkInfosForUniqueWork(
            "${UploadWorker.WORK_NAME}_periodic"
        ).get()
        assertEquals(1, workInfos.size)
    }
}
