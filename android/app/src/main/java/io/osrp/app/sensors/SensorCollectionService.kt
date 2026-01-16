package io.osrp.app.sensors

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import io.osrp.app.R
import io.osrp.app.data.repository.AuthRepository
import io.osrp.app.data.repository.DataRepository
import io.osrp.app.ui.main.MainActivity
import kotlinx.coroutines.*

/**
 * Foreground service for continuous sensor data collection
 * Runs in the background with a persistent notification
 */
class SensorCollectionService : Service() {

    private lateinit var dataRepository: DataRepository
    private lateinit var authRepository: AuthRepository
    private var accelerometerModule: AccelerometerModule? = null

    private val serviceScope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    // Wake lock to keep CPU awake during collection
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()

        // Initialize repositories
        dataRepository = DataRepository(applicationContext)
        authRepository = AuthRepository(applicationContext)

        // Create notification channel
        createNotificationChannel()

        // Acquire wake lock
        acquireWakeLock()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_COLLECTION -> {
                startSensorCollection()
            }
            ACTION_STOP_COLLECTION -> {
                stopSensorCollection()
                stopSelf()
            }
        }

        return START_STICKY  // Restart service if killed by system
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null  // Not a bound service
    }

    override fun onDestroy() {
        super.onDestroy()

        // Stop all sensor collection
        stopSensorCollection()

        // Release wake lock
        releaseWakeLock()

        // Cancel coroutine scope
        serviceScope.cancel()
    }

    private fun startSensorCollection() {
        // Start foreground service with notification
        startForeground(NOTIFICATION_ID, createNotification())

        // Get user ID from auth repository
        val userId = authRepository.getUserEmail() ?: "unknown_user"

        // Initialize and start accelerometer module
        accelerometerModule = AccelerometerModule(
            context = applicationContext,
            dataRepository = dataRepository,
            userId = userId,
            samplingRateHz = 5  // 5 Hz sampling rate
        )

        serviceScope.launch {
            try {
                accelerometerModule?.startCollection()
            } catch (e: Exception) {
                // Log error and stop service
                stopSelf()
            }
        }
    }

    private fun stopSensorCollection() {
        serviceScope.launch {
            try {
                accelerometerModule?.stopCollection()
                accelerometerModule?.cleanup()
                accelerometerModule = null
            } catch (e: Exception) {
                // Log error
            }
        }
    }

    private fun createNotification(): Notification {
        // Intent to open main activity when notification is tapped
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        // Intent to stop collection
        val stopIntent = Intent(this, SensorCollectionService::class.java).apply {
            action = ACTION_STOP_COLLECTION
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("OSRP Sensor Collection")
            .setContentText("Collecting accelerometer data")
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentIntent(pendingIntent)
            .addAction(
                android.R.drawable.ic_delete,
                "Stop",
                stopPendingIntent
            )
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Sensor Collection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notification for ongoing sensor data collection"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "OSRP::SensorCollectionWakeLock"
        ).apply {
            acquire(10 * 60 * 60 * 1000L)  // 10 hours max
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
    }

    companion object {
        private const val CHANNEL_ID = "sensor_collection_channel"
        private const val NOTIFICATION_ID = 1001

        const val ACTION_START_COLLECTION = "io.osrp.app.ACTION_START_COLLECTION"
        const val ACTION_STOP_COLLECTION = "io.osrp.app.ACTION_STOP_COLLECTION"

        /**
         * Start sensor collection service
         */
        fun startCollection(context: Context) {
            val intent = Intent(context, SensorCollectionService::class.java).apply {
                action = ACTION_START_COLLECTION
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        /**
         * Stop sensor collection service
         */
        fun stopCollection(context: Context) {
            val intent = Intent(context, SensorCollectionService::class.java).apply {
                action = ACTION_STOP_COLLECTION
            }
            context.startService(intent)
        }
    }
}
