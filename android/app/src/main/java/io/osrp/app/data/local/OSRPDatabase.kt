package io.osrp.app.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import io.osrp.app.data.local.converter.Converters
import io.osrp.app.data.local.dao.*
import io.osrp.app.data.local.entity.*

/**
 * OSRP Room Database
 * Main database for local data storage
 */
@Database(
    entities = [
        SensorReading::class,
        Event::class,
        DeviceState::class,
        UploadQueue::class
    ],
    version = 1,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class OSRPDatabase : RoomDatabase() {

    /**
     * Sensor readings DAO
     */
    abstract fun sensorReadingDao(): SensorReadingDao

    /**
     * Events DAO
     */
    abstract fun eventDao(): EventDao

    /**
     * Device states DAO
     */
    abstract fun deviceStateDao(): DeviceStateDao

    /**
     * Upload queue DAO
     */
    abstract fun uploadQueueDao(): UploadQueueDao

    companion object {
        @Volatile
        private var INSTANCE: OSRPDatabase? = null

        private const val DATABASE_NAME = "osrp_database"

        /**
         * Get database instance (singleton pattern)
         */
        fun getInstance(context: Context): OSRPDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    OSRPDatabase::class.java,
                    DATABASE_NAME
                )
                    .fallbackToDestructiveMigration() // For development - remove in production
                    .build()

                INSTANCE = instance
                instance
            }
        }

        /**
         * Get in-memory database instance (for testing)
         */
        fun getInMemoryInstance(context: Context): OSRPDatabase {
            return Room.inMemoryDatabaseBuilder(
                context.applicationContext,
                OSRPDatabase::class.java
            )
                .allowMainThreadQueries() // For testing only
                .build()
        }

        /**
         * Close database and clear instance (for testing)
         */
        fun closeInstance() {
            INSTANCE?.close()
            INSTANCE = null
        }
    }
}
