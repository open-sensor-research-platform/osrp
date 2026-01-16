package io.osrp.app.ui.auth

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import io.osrp.app.data.Result
import io.osrp.app.data.repository.AuthRepository
import kotlinx.coroutines.launch

/**
 * ViewModel for Login screen
 * Handles login logic and UI state
 */
class LoginViewModel(application: Application) : AndroidViewModel(application) {

    private val authRepository = AuthRepository(application.applicationContext)

    // LiveData for UI state
    private val _loginState = MutableLiveData<LoginState>()
    val loginState: LiveData<LoginState> = _loginState

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    private val _errorMessage = MutableLiveData<String?>()
    val errorMessage: LiveData<String?> = _errorMessage

    /**
     * Attempt to login with email and password
     */
    fun login(email: String, password: String) {
        // Validate input
        if (email.isBlank()) {
            _errorMessage.value = "Email is required"
            return
        }

        if (password.isBlank()) {
            _errorMessage.value = "Password is required"
            return
        }

        if (!android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            _errorMessage.value = "Please enter a valid email"
            return
        }

        // Clear previous error
        _errorMessage.value = null

        // Show loading
        _isLoading.value = true

        viewModelScope.launch {
            when (val result = authRepository.login(email, password)) {
                is Result.Success -> {
                    _isLoading.value = false
                    _loginState.value = LoginState.Success
                }
                is Result.Error -> {
                    _isLoading.value = false
                    _errorMessage.value = result.exception.message ?: "Login failed"
                    _loginState.value = LoginState.Error(result.exception.message ?: "Unknown error")
                }
                Result.Loading -> {
                    // Already handled by _isLoading
                }
            }
        }
    }

    /**
     * Clear error message
     */
    fun clearError() {
        _errorMessage.value = null
    }
}

/**
 * Login state sealed class
 */
sealed class LoginState {
    object Success : LoginState()
    data class Error(val message: String) : LoginState()
}
