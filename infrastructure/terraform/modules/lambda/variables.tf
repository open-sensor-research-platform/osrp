variable "study_name" {
  description = "Study name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "python3.11"
}

variable "auth_lambda_memory" {
  description = "Memory size for auth Lambda (MB)"
  type        = number
  default     = 256
}

variable "data_upload_lambda_memory" {
  description = "Memory size for data upload Lambda (MB)"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Lambda timeout (seconds)"
  type        = number
  default     = 30
}

variable "lambda_log_retention" {
  description = "CloudWatch log retention (days)"
  type        = number
  default     = 30
}

# Cognito variables
variable "user_pool_id" {
  description = "Cognito User Pool ID"
  type        = string
}

variable "user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  type        = string
}

variable "user_pool_arn" {
  description = "Cognito User Pool ARN"
  type        = string
}

# DynamoDB variables
variable "sensor_table_name" {
  description = "Sensor time series table name"
  type        = string
}

variable "sensor_table_arn" {
  description = "Sensor time series table ARN"
  type        = string
}

variable "event_table_name" {
  description = "Event log table name"
  type        = string
}

variable "event_table_arn" {
  description = "Event log table ARN"
  type        = string
}

variable "device_state_table_name" {
  description = "Device state table name"
  type        = string
}

variable "device_state_table_arn" {
  description = "Device state table ARN"
  type        = string
}

variable "participant_table_name" {
  description = "Participant status table name"
  type        = string
}

variable "participant_table_arn" {
  description = "Participant status table ARN"
  type        = string
}

# S3 variables
variable "data_bucket_name" {
  description = "Data bucket name"
  type        = string
}

variable "data_bucket_arn" {
  description = "Data bucket ARN"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
