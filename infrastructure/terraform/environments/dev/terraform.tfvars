# Development Environment Configuration

environment = "dev"
study_name  = "osrp"
aws_region  = "us-west-2"

# DynamoDB Configuration
enable_point_in_time_recovery = false  # Cost savings for dev
enable_dynamodb_encryption     = true

# S3 Configuration
enable_versioning  = true
log_retention_days = 30  # Shorter retention for dev

# Cognito Configuration
password_minimum_length    = 8
token_validity_access      = 60
token_validity_id          = 60
token_validity_refresh     = 30
enable_deletion_protection = false

# Lambda Configuration
lambda_runtime            = "python3.11"
auth_lambda_memory        = 256
data_upload_lambda_memory = 512
lambda_timeout            = 30
lambda_log_retention      = 7  # Shorter retention for dev

# API Gateway Configuration
api_throttle_burst_limit = 500   # Lower limits for dev
api_throttle_rate_limit  = 1000
enable_api_logging       = true

# Additional Tags (optional)
# These tags supplement the mandatory tags (Tool, Project, Environment, ManagedBy, Version)
# Use these for cost allocation, compliance tracking, and resource management
additional_tags = {
  Owner       = "Development Team"        # Team or person responsible
  CostCenter  = "Research"                # Cost center for billing
  Compliance  = "PHI"                     # Data classification (PHI, PII, etc.)
  Department  = "Psychology"              # Academic department
  # IRB       = "2024-001"                # IRB protocol number (if applicable)
  # Grant     = "NIH-R01-123456"          # Grant funding this work
  # StudyPI   = "Dr. Jane Smith"          # Principal investigator
}
