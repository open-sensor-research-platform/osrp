package io.osrp.app.ui.main

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import io.osrp.app.R
import io.osrp.app.data.repository.AuthRepository
import io.osrp.app.databinding.ActivityMainBinding
import io.osrp.app.sensors.SensorCollectionService
import io.osrp.app.ui.auth.LoginActivity

/**
 * Main Activity
 * Entry point for the OSRP Android app
 * Checks authentication state and shows appropriate screen
 */
class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var authRepository: AuthRepository

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize AuthRepository
        authRepository = AuthRepository(applicationContext)

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

        // Show logged in user email
        val userEmail = authRepository.getUserEmail()
        if (userEmail != null) {
            binding.userEmailText.text = "Logged in as: $userEmail"
        }

        // Add buttons for sensor collection (temporary UI for testing)
        binding.startSensorButton.setOnClickListener {
            startSensorCollection()
        }

        binding.stopSensorButton.setOnClickListener {
            stopSensorCollection()
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
        Toast.makeText(this, "Started sensor collection", Toast.LENGTH_SHORT).show()
    }

    private fun stopSensorCollection() {
        SensorCollectionService.stopCollection(this)
        Toast.makeText(this, "Stopped sensor collection", Toast.LENGTH_SHORT).show()
    }
}
