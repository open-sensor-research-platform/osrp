# ============================================================================
# OSRP Infrastructure - Main Configuration
# ============================================================================

locals {
  name_prefix = "${var.study_name}-${var.environment}"
  account_id  = data.aws_caller_identity.current.account_id

  common_tags = merge(
    {
      Project     = "OSRP"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.additional_tags
  )
}

data "aws_caller_identity" "current" {}

# ============================================================================
# DynamoDB Tables
# ============================================================================

module "dynamodb" {
  source = "./modules/dynamodb"

  study_name                    = var.study_name
  environment                   = var.environment
  enable_point_in_time_recovery = var.enable_point_in_time_recovery
  enable_encryption             = var.enable_dynamodb_encryption

  tags = local.common_tags
}

# ============================================================================
# S3 Buckets
# ============================================================================

module "s3" {
  source = "./modules/s3"

  study_name          = var.study_name
  environment         = var.environment
  account_id          = local.account_id
  enable_versioning   = var.enable_versioning
  log_retention_days  = var.log_retention_days

  tags = local.common_tags
}

# ============================================================================
# Cognito User Pool
# ============================================================================

module "cognito" {
  source = "./modules/cognito"

  study_name                 = var.study_name
  environment                = var.environment
  account_id                 = local.account_id
  password_minimum_length    = var.password_minimum_length
  token_validity_access      = var.token_validity_access
  token_validity_id          = var.token_validity_id
  token_validity_refresh     = var.token_validity_refresh
  enable_deletion_protection = var.enable_deletion_protection

  tags = local.common_tags
}

# ============================================================================
# Lambda Functions
# ============================================================================

module "lambda" {
  source = "./modules/lambda"

  study_name                  = var.study_name
  environment                 = var.environment
  lambda_runtime              = var.lambda_runtime
  auth_lambda_memory          = var.auth_lambda_memory
  data_upload_lambda_memory   = var.data_upload_lambda_memory
  lambda_timeout              = var.lambda_timeout
  lambda_log_retention        = var.lambda_log_retention

  # Dependencies from other modules
  user_pool_id               = module.cognito.user_pool_id
  user_pool_client_id        = module.cognito.user_pool_client_id
  user_pool_arn              = module.cognito.user_pool_arn
  sensor_table_name          = module.dynamodb.sensor_time_series_table_name
  event_table_name           = module.dynamodb.event_log_table_name
  device_state_table_name    = module.dynamodb.device_state_table_name
  participant_table_name     = module.dynamodb.participant_status_table_name
  sensor_table_arn           = module.dynamodb.sensor_time_series_table_arn
  event_table_arn            = module.dynamodb.event_log_table_arn
  device_state_table_arn     = module.dynamodb.device_state_table_arn
  participant_table_arn      = module.dynamodb.participant_status_table_arn
  data_bucket_name           = module.s3.data_bucket_name
  data_bucket_arn            = module.s3.data_bucket_arn

  tags = local.common_tags
}

# ============================================================================
# API Gateway
# ============================================================================

module "api_gateway" {
  source = "./modules/api_gateway"

  study_name             = var.study_name
  environment            = var.environment
  user_pool_arn          = module.cognito.user_pool_arn
  auth_lambda_arn        = module.lambda.auth_lambda_arn
  auth_lambda_name       = module.lambda.auth_lambda_name
  data_upload_lambda_arn = module.lambda.data_upload_lambda_arn
  data_upload_lambda_name = module.lambda.data_upload_lambda_name
  throttle_burst_limit   = var.api_throttle_burst_limit
  throttle_rate_limit    = var.api_throttle_rate_limit
  enable_logging         = var.enable_api_logging

  tags = local.common_tags
}
