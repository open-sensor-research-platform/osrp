package io.osrp.app.util

import androidx.work.Data

/**
 * Helper function to create WorkData from vararg pairs
 */
fun workDataOf(vararg pairs: Pair<String, Any?>): Data {
    val builder = Data.Builder()
    for ((key, value) in pairs) {
        when (value) {
            null -> builder.putString(key, null)
            is String -> builder.putString(key, value)
            is Int -> builder.putInt(key, value)
            is Long -> builder.putLong(key, value)
            is Boolean -> builder.putBoolean(key, value)
            is Float -> builder.putFloat(key, value)
            is Double -> builder.putDouble(key, value)
            else -> builder.putString(key, value.toString())
        }
    }
    return builder.build()
}
