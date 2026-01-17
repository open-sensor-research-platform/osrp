variable "study_name" {
  description = "Study name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "user_pool_arn" {
  description = "Cognito User Pool ARN for authorizer"
  type        = string
}

variable "auth_lambda_arn" {
  description = "Auth Lambda function invoke ARN"
  type        = string
}

variable "auth_lambda_name" {
  description = "Auth Lambda function name"
  type        = string
}

variable "data_upload_lambda_arn" {
  description = "Data Upload Lambda function invoke ARN"
  type        = string
}

variable "data_upload_lambda_name" {
  description = "Data Upload Lambda function name"
  type        = string
}

variable "throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 5000
}

variable "throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 10000
}

variable "enable_logging" {
  description = "Enable API Gateway logging"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
