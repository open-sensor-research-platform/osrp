package io.osrp.app.util

import android.content.Context
import android.content.SharedPreferences

/**
 * Manages app preferences using SharedPreferences
 */
class PreferencesManager(context: Context) {

    private val prefs: SharedPreferences = context.getSharedPreferences(
        PREFS_NAME,
        Context.MODE_PRIVATE
    )

    /**
     * Upload settings
     */
    var uploadWifiOnly: Boolean
        get() = prefs.getBoolean(KEY_UPLOAD_WIFI_ONLY, true)
        set(value) = prefs.edit().putBoolean(KEY_UPLOAD_WIFI_ONLY, value).apply()

    var uploadRequiresCharging: Boolean
        get() = prefs.getBoolean(KEY_UPLOAD_REQUIRES_CHARGING, false)
        set(value) = prefs.edit().putBoolean(KEY_UPLOAD_REQUIRES_CHARGING, value).apply()

    var uploadIntervalMinutes: Long
        get() = prefs.getLong(KEY_UPLOAD_INTERVAL_MINUTES, 15L)
        set(value) = prefs.edit().putLong(KEY_UPLOAD_INTERVAL_MINUTES, value).apply()

    var autoUploadEnabled: Boolean
        get() = prefs.getBoolean(KEY_AUTO_UPLOAD_ENABLED, true)
        set(value) = prefs.edit().putBoolean(KEY_AUTO_UPLOAD_ENABLED, value).apply()

    /**
     * Sensor collection settings
     */
    var sensorCollectionEnabled: Boolean
        get() = prefs.getBoolean(KEY_SENSOR_COLLECTION_ENABLED, false)
        set(value) = prefs.edit().putBoolean(KEY_SENSOR_COLLECTION_ENABLED, value).apply()

    var accelerometerSamplingRateHz: Int
        get() = prefs.getInt(KEY_ACCELEROMETER_SAMPLING_RATE_HZ, 5)
        set(value) = prefs.edit().putInt(KEY_ACCELEROMETER_SAMPLING_RATE_HZ, value).apply()

    companion object {
        private const val PREFS_NAME = "osrp_preferences"

        // Upload preferences
        private const val KEY_UPLOAD_WIFI_ONLY = "upload_wifi_only"
        private const val KEY_UPLOAD_REQUIRES_CHARGING = "upload_requires_charging"
        private const val KEY_UPLOAD_INTERVAL_MINUTES = "upload_interval_minutes"
        private const val KEY_AUTO_UPLOAD_ENABLED = "auto_upload_enabled"

        // Sensor collection preferences
        private const val KEY_SENSOR_COLLECTION_ENABLED = "sensor_collection_enabled"
        private const val KEY_ACCELEROMETER_SAMPLING_RATE_HZ = "accelerometer_sampling_rate_hz"
    }
}
