package io.osrp.app.ui.main

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import io.osrp.app.R
import io.osrp.app.databinding.ActivityMainBinding

/**
 * Main Activity
 * Entry point for the OSRP Android app
 */
class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

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

        // TODO: Check if user is logged in
        // TODO: Navigate to appropriate screen (login or home)
    }
}
