package io.osrp.app.ui.main

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.Toast
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import io.osrp.app.R
import io.osrp.app.data.repository.AuthRepository
import io.osrp.app.databinding.ActivityMainBinding
import io.osrp.app.sensors.SensorCollectionService
import io.osrp.app.ui.auth.LoginActivity
import io.osrp.app.upload.UploadScheduler
import io.osrp.app.util.PreferencesManager
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Main Activity
 * Entry point for the OSRP Android app
 * Checks authentication state and shows appropriate screen
 */
class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var authRepository: AuthRepository
    private lateinit var uploadScheduler: UploadScheduler
    private lateinit var preferencesManager: PreferencesManager
    private val viewModel: StatusViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize repositories and managers
        authRepository = AuthRepository(applicationContext)
        uploadScheduler = UploadScheduler(applicationContext)
        preferencesManager = PreferencesManager(applicationContext)

        // Check if user is logged in
        if (!authRepository.isLoggedIn()) {
            navigateToLogin()
            return
        }

        // Initialize View Binding
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupUI()
    }

    private fun setupUI() {
        // Set app title
        binding.appTitle.text = getString(R.string.welcome_title)
        binding.appSubtitle.text = getString(R.string.welcome_subtitle)
        binding.versionText.text = getString(R.string.version)

        // Button listeners
        binding.startSensorButton.setOnClickListener {
            startSensorCollection()
        }

        binding.stopSensorButton.setOnClickListener {
            stopSensorCollection()
        }

        binding.uploadNowButton.setOnClickListener {
            uploadNow()
        }

        binding.scheduleUploadButton.setOnClickListener {
            schedulePeriodicUpload()
        }

        binding.refreshButton.setOnClickListener {
            viewModel.refreshStatus()
            Toast.makeText(this, "Refreshing status...", Toast.LENGTH_SHORT).show()
        }

        // Observe ViewModel
        observeViewModel()
    }

    private fun observeViewModel() {
        // User email
        viewModel.userEmail.observe(this) { email ->
            binding.userEmailText.text = "Logged in as: $email"
        }

        // Connection status
        viewModel.connectionStatus.observe(this) { status ->
            val (statusText, statusColor) = when (status) {
                ConnectionStatus.CONNECTED -> "Connected" to getColor(R.color.md_theme_primary)
                ConnectionStatus.NOT_AUTHENTICATED -> "Not Authenticated" to getColor(R.color.md_theme_error)
                ConnectionStatus.TOKEN_EXPIRED -> "Token Expired" to getColor(R.color.md_theme_error)
                ConnectionStatus.ERROR -> "Error" to getColor(R.color.md_theme_error)
                else -> "Unknown" to getColor(R.color.md_theme_on_surface)
            }
            binding.connectionStatusText.text = statusText
            binding.connectionStatusText.setTextColor(statusColor)
        }

        // Collection status
        viewModel.isCollecting.observe(this) { isCollecting ->
            val (statusText, statusColor) = if (isCollecting) {
                "Running" to getColor(R.color.md_theme_primary)
            } else {
                "Stopped" to getColor(R.color.md_theme_on_surface)
            }
            binding.collectionStatusText.text = statusText
            binding.collectionStatusText.setTextColor(statusColor)

            // Update button visibility
            binding.startSensorButton.visibility = if (isCollecting) View.GONE else View.VISIBLE
            binding.stopSensorButton.visibility = if (isCollecting) View.VISIBLE else View.GONE
        }

        // Upload status
        viewModel.isUploadRunning.observe(this) { isRunning ->
            val statusText = if (isRunning) "Uploading..." else "Idle"
            binding.uploadStatusText.text = statusText
        }

        viewModel.autoUploadEnabled.observe(this) { enabled ->
            val statusText = if (enabled) "Enabled" else "Disabled"
            binding.autoUploadStatusText.text = statusText
        }

        // Pending counts
        viewModel.pendingSensorReadings.observe(this) { count ->
            binding.pendingSensorReadingsText.text = count.toString()
        }

        viewModel.totalPending.observe(this) { total ->
            binding.totalPendingText.text = "$total records pending upload"
        }
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.main_menu, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_logout -> {
                logout()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    private fun logout() {
        authRepository.logout()
        Toast.makeText(this, R.string.logout_success, Toast.LENGTH_SHORT).show()
        navigateToLogin()
    }

    private fun navigateToLogin() {
        val intent = Intent(this, LoginActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish()
    }

    private fun startSensorCollection() {
        SensorCollectionService.startCollection(this)
        viewModel.updateCollectionStatus(true)
        Toast.makeText(this, "Started sensor collection", Toast.LENGTH_SHORT).show()
    }

    private fun stopSensorCollection() {
        SensorCollectionService.stopCollection(this)
        viewModel.updateCollectionStatus(false)
        Toast.makeText(this, "Stopped sensor collection", Toast.LENGTH_SHORT).show()
    }

    private fun uploadNow() {
        val wifiOnly = preferencesManager.uploadWifiOnly
        val requiresCharging = preferencesManager.uploadRequiresCharging

        uploadScheduler.scheduleImmediateUpload(
            wifiOnly = wifiOnly,
            requiresCharging = requiresCharging
        )

        val message = if (wifiOnly) {
            "Upload scheduled (WiFi only)"
        } else {
            "Upload scheduled"
        }
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
    }

    private fun schedulePeriodicUpload() {
        val intervalMinutes = preferencesManager.uploadIntervalMinutes
        val wifiOnly = preferencesManager.uploadWifiOnly
        val requiresCharging = preferencesManager.uploadRequiresCharging

        uploadScheduler.schedulePeriodicUpload(
            intervalMinutes = intervalMinutes,
            wifiOnly = wifiOnly,
            requiresCharging = requiresCharging
        )

        preferencesManager.autoUploadEnabled = true

        Toast.makeText(
            this,
            "Scheduled upload every $intervalMinutes minutes",
            Toast.LENGTH_SHORT
        ).show()
    }
}
