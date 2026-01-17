# ============================================================================
# API Gateway Module
# ============================================================================

locals {
  name_prefix = "${var.study_name}-${var.environment}"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ============================================================================
# REST API
# ============================================================================

resource "aws_api_gateway_rest_api" "main" {
  name        = "${local.name_prefix}-api"
  description = "OSRP REST API for mobile apps"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-api"
    }
  )
}

# ============================================================================
# Cognito Authorizer
# ============================================================================

resource "aws_api_gateway_authorizer" "cognito" {
  name            = "${local.name_prefix}-cognito-authorizer"
  type            = "COGNITO_USER_POOLS"
  rest_api_id     = aws_api_gateway_rest_api.main.id
  identity_source = "method.request.header.Authorization"
  provider_arns   = [var.user_pool_arn]
}

# ============================================================================
# API Resources
# ============================================================================

# /auth
resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "auth"
}

# /auth/register
resource "aws_api_gateway_resource" "auth_register" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "register"
}

# /auth/login
resource "aws_api_gateway_resource" "auth_login" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "login"
}

# /auth/refresh
resource "aws_api_gateway_resource" "auth_refresh" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "refresh"
}

# /data
resource "aws_api_gateway_resource" "data" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "data"
}

# /data/sensor
resource "aws_api_gateway_resource" "data_sensor" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.data.id
  path_part   = "sensor"
}

# /data/event
resource "aws_api_gateway_resource" "data_event" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.data.id
  path_part   = "event"
}

# /data/device-state
resource "aws_api_gateway_resource" "data_device_state" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.data.id
  path_part   = "device-state"
}

# /data/presigned-url
resource "aws_api_gateway_resource" "data_presigned_url" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.data.id
  path_part   = "presigned-url"
}

# ============================================================================
# Lambda Permissions
# ============================================================================

resource "aws_lambda_permission" "auth" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.auth_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "data_upload" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.data_upload_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*/*"
}

# ============================================================================
# Auth Methods (No Authorization Required)
# ============================================================================

# POST /auth/register
resource "aws_api_gateway_method" "auth_register" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.auth_register.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_register" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.auth_register.id
  http_method             = aws_api_gateway_method.auth_register.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.auth_lambda_arn
}

# POST /auth/login
resource "aws_api_gateway_method" "auth_login" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.auth_login.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_login" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.auth_login.id
  http_method             = aws_api_gateway_method.auth_login.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.auth_lambda_arn
}

# POST /auth/refresh
resource "aws_api_gateway_method" "auth_refresh" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.auth_refresh.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_refresh" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.auth_refresh.id
  http_method             = aws_api_gateway_method.auth_refresh.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.auth_lambda_arn
}

# ============================================================================
# Data Methods (Cognito Authorization Required)
# ============================================================================

# POST /data/sensor
resource "aws_api_gateway_method" "data_sensor" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.data_sensor.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "data_sensor" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.data_sensor.id
  http_method             = aws_api_gateway_method.data_sensor.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.data_upload_lambda_arn
}

# POST /data/event
resource "aws_api_gateway_method" "data_event" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.data_event.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "data_event" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.data_event.id
  http_method             = aws_api_gateway_method.data_event.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.data_upload_lambda_arn
}

# POST /data/device-state
resource "aws_api_gateway_method" "data_device_state" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.data_device_state.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "data_device_state" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.data_device_state.id
  http_method             = aws_api_gateway_method.data_device_state.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.data_upload_lambda_arn
}

# GET /data/presigned-url
resource "aws_api_gateway_method" "data_presigned_url" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.data_presigned_url.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "data_presigned_url" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.data_presigned_url.id
  http_method             = aws_api_gateway_method.data_presigned_url.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.data_upload_lambda_arn
}

# ============================================================================
# API Deployment
# ============================================================================

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  depends_on = [
    aws_api_gateway_integration.auth_register,
    aws_api_gateway_integration.auth_login,
    aws_api_gateway_integration.auth_refresh,
    aws_api_gateway_integration.data_sensor,
    aws_api_gateway_integration.data_event,
    aws_api_gateway_integration.data_device_state,
    aws_api_gateway_integration.data_presigned_url,
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.auth_register.id,
      aws_api_gateway_integration.auth_login.id,
      aws_api_gateway_integration.auth_refresh.id,
      aws_api_gateway_integration.data_sensor.id,
      aws_api_gateway_integration.data_event.id,
      aws_api_gateway_integration.data_device_state.id,
      aws_api_gateway_integration.data_presigned_url.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# API Stage
# ============================================================================

resource "aws_api_gateway_stage" "main" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.main.id
  stage_name    = var.environment
  description   = "${var.environment} stage"

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-stage"
    }
  )
}

resource "aws_api_gateway_method_settings" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    logging_level          = var.enable_logging ? "INFO" : "OFF"
    data_trace_enabled     = false
    metrics_enabled        = true
    throttling_burst_limit = var.throttle_burst_limit
    throttling_rate_limit  = var.throttle_rate_limit
  }
}

# ============================================================================
# CloudWatch Log Group
# ============================================================================

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.name_prefix}-api"
  retention_in_days = 30

  tags = var.tags
}
