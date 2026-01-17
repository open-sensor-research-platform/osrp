# ============================================================================
# API Gateway Outputs
# ============================================================================

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.api_gateway.api_endpoint
}

output "rest_api_id" {
  description = "REST API ID"
  value       = module.api_gateway.rest_api_id
}

# ============================================================================
# Cognito Outputs
# ============================================================================

output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = module.cognito.user_pool_client_id
  sensitive   = true
}

output "identity_pool_id" {
  description = "Cognito Identity Pool ID"
  value       = module.cognito.identity_pool_id
}

output "user_pool_domain" {
  description = "Cognito User Pool Domain URL"
  value       = module.cognito.user_pool_domain
}

# ============================================================================
# DynamoDB Outputs
# ============================================================================

output "participant_status_table_name" {
  description = "ParticipantStatus table name"
  value       = module.dynamodb.participant_status_table_name
}

output "sensor_time_series_table_name" {
  description = "SensorTimeSeries table name"
  value       = module.dynamodb.sensor_time_series_table_name
}

output "event_log_table_name" {
  description = "EventLog table name"
  value       = module.dynamodb.event_log_table_name
}

output "device_state_table_name" {
  description = "DeviceState table name"
  value       = module.dynamodb.device_state_table_name
}

# ============================================================================
# S3 Outputs
# ============================================================================

output "data_bucket_name" {
  description = "Data bucket name"
  value       = module.s3.data_bucket_name
}

output "logging_bucket_name" {
  description = "Logging bucket name"
  value       = module.s3.logging_bucket_name
}

# ============================================================================
# Lambda Outputs
# ============================================================================

output "auth_lambda_function_name" {
  description = "Auth Lambda function name"
  value       = module.lambda.auth_lambda_name
}

output "data_upload_lambda_function_name" {
  description = "Data Upload Lambda function name"
  value       = module.lambda.data_upload_lambda_name
}

# ============================================================================
# Next Steps Output
# ============================================================================

output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT
    Deployment complete! Next steps:

    1. Deploy Lambda code:
       aws lambda update-function-code --function-name ${module.lambda.auth_lambda_name} --zip-file fileb://auth_handler.zip
       aws lambda update-function-code --function-name ${module.lambda.data_upload_lambda_name} --zip-file fileb://data_upload_handler.zip

    2. Test API endpoint:
       curl -X POST ${module.api_gateway.api_endpoint}/auth/register \
         -H "Content-Type: application/json" \
         -d '{"email":"test@example.com","password":"Test1234!"}'

    3. Configure mobile apps with:
       - API Endpoint: ${module.api_gateway.api_endpoint}
       - User Pool ID: ${module.cognito.user_pool_id}
       - User Pool Client ID: ${module.cognito.user_pool_client_id}
       - Identity Pool ID: ${module.cognito.identity_pool_id}
       - Region: ${var.aws_region}
  EOT
}
