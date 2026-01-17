variable "study_name" {
  description = "Study name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "password_minimum_length" {
  description = "Minimum password length"
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
  description = "Enable deletion protection for User Pool"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
