package io.osrp.app.ui.main

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import io.osrp.app.data.repository.AuthRepository
import io.osrp.app.data.repository.DataRepository
import io.osrp.app.upload.UploadScheduler
import io.osrp.app.util.PreferencesManager
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * ViewModel for status dashboard
 * Manages real-time status updates for data collection and uploads
 */
class StatusViewModel(application: Application) : AndroidViewModel(application) {

    private val authRepository = AuthRepository(application)
    private val dataRepository = DataRepository(application)
    private val uploadScheduler = UploadScheduler(application)
    private val preferencesManager = PreferencesManager(application)

    // Authentication status
    private val _isAuthenticated = MutableLiveData<Boolean>()
    val isAuthenticated: LiveData<Boolean> = _isAuthenticated

    private val _userEmail = MutableLiveData<String>()
    val userEmail: LiveData<String> = _userEmail

    // Collection status
    private val _isCollecting = MutableLiveData<Boolean>()
    val isCollecting: LiveData<Boolean> = _isCollecting

    // Upload status
    private val _lastUploadTime = MutableLiveData<Long?>()
    val lastUploadTime: LiveData<Long?> = _lastUploadTime

    private val _isUploadRunning = MutableLiveData<Boolean>()
    val isUploadRunning: LiveData<Boolean> = _isUploadRunning

    private val _autoUploadEnabled = MutableLiveData<Boolean>()
    val autoUploadEnabled: LiveData<Boolean> = _autoUploadEnabled

    // Pending counts
    private val _pendingSensorReadings = MutableLiveData<Int>()
    val pendingSensorReadings: LiveData<Int> = _pendingSensorReadings

    private val _pendingEvents = MutableLiveData<Int>()
    val pendingEvents: LiveData<Int> = _pendingEvents

    private val _pendingDeviceStates = MutableLiveData<Int>()
    val pendingDeviceStates: LiveData<Int> = _pendingDeviceStates

    // Total pending
    private val _totalPending = MutableLiveData<Int>()
    val totalPending: LiveData<Int> = _totalPending

    // Connection status
    private val _connectionStatus = MutableLiveData<ConnectionStatus>()
    val connectionStatus: LiveData<ConnectionStatus> = _connectionStatus

    init {
        refreshStatus()
        startPeriodicRefresh()
    }

    /**
     * Refresh all status information
     */
    fun refreshStatus() {
        viewModelScope.launch {
            // Authentication status
            _isAuthenticated.value = authRepository.isLoggedIn()
            _userEmail.value = authRepository.getUserEmail()

            // Collection status
            _isCollecting.value = preferencesManager.sensorCollectionEnabled

            // Upload status
            _isUploadRunning.value = uploadScheduler.isUploadRunning()
            _autoUploadEnabled.value = preferencesManager.autoUploadEnabled

            // Pending counts
            val counts = dataRepository.getPendingCounts()
            if (counts is io.osrp.app.data.Result.Success) {
                _pendingSensorReadings.value = counts.data["sensor_readings"] ?: 0
                _pendingEvents.value = counts.data["events"] ?: 0
                _pendingDeviceStates.value = counts.data["device_states"] ?: 0

                val total = (counts.data["sensor_readings"] ?: 0) +
                           (counts.data["events"] ?: 0) +
                           (counts.data["device_states"] ?: 0)
                _totalPending.value = total
            }

            // Connection status
            updateConnectionStatus()
        }
    }

    /**
     * Start periodic refresh of status (every 5 seconds)
     */
    private fun startPeriodicRefresh() {
        viewModelScope.launch {
            while (true) {
                delay(5000) // Refresh every 5 seconds
                refreshStatus()
            }
        }
    }

    /**
     * Update connection status
     */
    private fun updateConnectionStatus() {
        viewModelScope.launch {
            val status = if (!authRepository.isLoggedIn()) {
                ConnectionStatus.NOT_AUTHENTICATED
            } else {
                // Check if token is valid
                val hasValidToken = authRepository.getAuthorizationHeader() != null
                if (hasValidToken) {
                    ConnectionStatus.CONNECTED
                } else {
                    ConnectionStatus.TOKEN_EXPIRED
                }
            }
            _connectionStatus.value = status
        }
    }

    /**
     * Update collection status
     */
    fun updateCollectionStatus(isCollecting: Boolean) {
        _isCollecting.value = isCollecting
        preferencesManager.sensorCollectionEnabled = isCollecting
    }

    /**
     * Update auto-upload status
     */
    fun updateAutoUploadStatus(enabled: Boolean) {
        _autoUploadEnabled.value = enabled
        preferencesManager.autoUploadEnabled = enabled
    }
}

/**
 * Connection status enum
 */
enum class ConnectionStatus {
    NOT_AUTHENTICATED,
    TOKEN_EXPIRED,
    CONNECTED,
    ERROR
}
