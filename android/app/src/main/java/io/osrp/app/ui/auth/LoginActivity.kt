package io.osrp.app.ui.auth

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.Toast
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import io.osrp.app.R
import io.osrp.app.databinding.ActivityLoginBinding
import io.osrp.app.ui.main.MainActivity

/**
 * Login Activity
 * Handles user authentication
 */
class LoginActivity : AppCompatActivity() {

    private lateinit var binding: ActivityLoginBinding
    private val viewModel: LoginViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize View Binding
        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupUI()
        observeViewModel()
    }

    private fun setupUI() {
        // Login button click
        binding.loginButton.setOnClickListener {
            attemptLogin()
        }

        // Handle Enter key on password field
        binding.passwordEditText.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_DONE) {
                attemptLogin()
                true
            } else {
                false
            }
        }

        // Clear error when user starts typing
        binding.emailEditText.setOnFocusChangeListener { _, _ ->
            viewModel.clearError()
        }

        binding.passwordEditText.setOnFocusChangeListener { _, _ ->
            viewModel.clearError()
        }
    }

    private fun observeViewModel() {
        // Observe loading state
        viewModel.isLoading.observe(this) { isLoading ->
            if (isLoading) {
                binding.loginButton.text = ""
                binding.loginButton.isEnabled = false
                binding.loadingProgressBar.visibility = View.VISIBLE
                binding.errorTextView.visibility = View.GONE
            } else {
                binding.loginButton.text = getString(R.string.login)
                binding.loginButton.isEnabled = true
                binding.loadingProgressBar.visibility = View.GONE
            }
        }

        // Observe error messages
        viewModel.errorMessage.observe(this) { errorMessage ->
            if (errorMessage != null) {
                binding.errorTextView.text = errorMessage
                binding.errorTextView.visibility = View.VISIBLE
            } else {
                binding.errorTextView.visibility = View.GONE
            }
        }

        // Observe login state
        viewModel.loginState.observe(this) { loginState ->
            when (loginState) {
                is LoginState.Success -> {
                    Toast.makeText(this, R.string.login_success, Toast.LENGTH_SHORT).show()
                    navigateToMain()
                }
                is LoginState.Error -> {
                    // Error already shown via errorMessage LiveData
                }
            }
        }
    }

    private fun attemptLogin() {
        val email = binding.emailEditText.text.toString().trim()
        val password = binding.passwordEditText.text.toString()

        viewModel.login(email, password)
    }

    private fun navigateToMain() {
        val intent = Intent(this, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish()
    }
}
