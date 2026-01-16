package io.osrp.app.data

/**
 * A generic class that holds a value or an error.
 * Used as a wrapper for data returned from repositories.
 */
sealed class Result<out T> {
    data class Success<out T>(val data: T) : Result<T>()
    data class Error(val exception: Exception) : Result<Nothing>()
    object Loading : Result<Nothing>()

    override fun toString(): String {
        return when (this) {
            is Success<*> -> "Success[data=$data]"
            is Error -> "Error[exception=$exception]"
            Loading -> "Loading"
        }
    }
}

/**
 * Helper function to check if Result is Success
 */
fun <T> Result<T>.isSuccess(): Boolean = this is Result.Success

/**
 * Helper function to get data from Result
 */
fun <T> Result<T>.getOrNull(): T? {
    return when (this) {
        is Result.Success -> data
        else -> null
    }
}
