# ============================================================================
# Core Configuration Variables
# ============================================================================

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "study_name" {
  description = "Study name for resource naming"
  type        = string
  default     = "osrp"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.study_name))
    error_message = "Study name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-west-2"
}

# ============================================================================
# DynamoDB Configuration
# ============================================================================

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for DynamoDB tables"
  type        = bool
  default     = true
}

variable "enable_dynamodb_encryption" {
  description = "Enable server-side encryption for DynamoDB tables"
  type        = bool
  default     = true
}

# ============================================================================
# S3 Configuration
# ============================================================================

variable "enable_versioning" {
  description = "Enable versioning for S3 data bucket"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain logs in logging bucket"
  type        = number
  default     = 90
}

# ============================================================================
# Cognito Configuration
# ============================================================================

variable "password_minimum_length" {
  description = "Minimum password length for Cognito users"
  type        = number
  default     = 8
}

variable "token_validity_access" {
  description = "Access token validity in minutes"
  type        = number
  default     = 60
}

variable "token_validity_id" {
  description = "ID token validity in minutes"
  type        = number
  default     = 60
}

variable "token_validity_refresh" {
  description = "Refresh token validity in days"
  type        = number
  default     = 30
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for Cognito User Pool (recommended for production)"
  type        = bool
  default     = false
}

# ============================================================================
# Lambda Configuration
# ============================================================================

variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "python3.11"
}

variable "auth_lambda_memory" {
  description = "Memory size for auth Lambda function (MB)"
  type        = number
  default     = 256
}

variable "data_upload_lambda_memory" {
  description = "Memory size for data upload Lambda function (MB)"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Lambda function timeout (seconds)"
  type        = number
  default     = 30
}

variable "lambda_log_retention" {
  description = "CloudWatch log retention for Lambda functions (days)"
  type        = number
  default     = 30
}

# ============================================================================
# API Gateway Configuration
# ============================================================================

variable "api_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 5000
}

variable "api_throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 10000
}

variable "enable_api_logging" {
  description = "Enable API Gateway logging"
  type        = bool
  default     = true
}

# ============================================================================
# Tags
# ============================================================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
