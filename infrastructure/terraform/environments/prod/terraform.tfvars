# Production Environment Configuration

environment = "prod"
study_name  = "osrp"
aws_region  = "us-west-2"

# DynamoDB Configuration
enable_point_in_time_recovery = true
enable_dynamodb_encryption     = true

# S3 Configuration
enable_versioning  = true
log_retention_days = 90

# Cognito Configuration
password_minimum_length    = 8
token_validity_access      = 60
token_validity_id          = 60
token_validity_refresh     = 30
enable_deletion_protection = true  # Enable for production

# Lambda Configuration
lambda_runtime            = "python3.11"
auth_lambda_memory        = 256
data_upload_lambda_memory = 512
lambda_timeout            = 30
lambda_log_retention      = 30

# API Gateway Configuration
api_throttle_burst_limit = 5000
api_throttle_rate_limit  = 10000
enable_api_logging       = true

# Additional Tags
additional_tags = {
  Owner       = "Production Team"
  CostCenter  = "Research"
  Compliance  = "PHI"
  Criticality = "High"
}
