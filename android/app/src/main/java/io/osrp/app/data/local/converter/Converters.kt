package io.osrp.app.data.local.converter

import androidx.room.TypeConverter

/**
 * Type converters for Room database
 * Handles conversion of complex types to/from database storage
 */
class Converters {

    @TypeConverter
    fun fromLong(value: Long): Long {
        return value
    }

    @TypeConverter
    fun toLong(value: Long): Long {
        return value
    }

    // Additional converters can be added here as needed
    // For example, if we need to convert lists or custom objects
}
