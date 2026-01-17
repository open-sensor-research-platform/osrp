# ============================================================================
# Lambda Functions Module
# ============================================================================

locals {
  name_prefix = "${var.study_name}-${var.environment}"
}

# ============================================================================
# Auth Lambda Execution Role
# ============================================================================

resource "aws_iam_role" "auth_lambda" {
  name = "${local.name_prefix}-auth-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-auth-lambda-role"
    }
  )
}

resource "aws_iam_role_policy" "auth_lambda_cognito" {
  name = "CognitoAccess"
  role = aws_iam_role.auth_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:SignUp",
          "cognito-idp:InitiateAuth",
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminGetUser",
          "cognito-idp:AdminSetUserPassword"
        ]
        Resource = var.user_pool_arn
      }
    ]
  })
}

# ============================================================================
# Auth Lambda Function
# ============================================================================

resource "aws_lambda_function" "auth" {
  function_name = "${local.name_prefix}-auth"
  role          = aws_iam_role.auth_lambda.arn
  runtime       = var.lambda_runtime
  handler       = "auth_handler.lambda_handler"
  timeout       = var.lambda_timeout
  memory_size   = var.auth_lambda_memory

  filename         = "${path.module}/placeholder.zip"
  source_code_hash = filebase64sha256("${path.module}/placeholder.zip")

  environment {
    variables = {
      USER_POOL_ID        = var.user_pool_id
      CLIENT_ID           = var.user_pool_client_id
      ENVIRONMENT         = var.environment
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-auth"
    }
  )

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      last_modified
    ]
  }
}

resource "aws_cloudwatch_log_group" "auth_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.auth.function_name}"
  retention_in_days = var.lambda_log_retention

  tags = var.tags
}

# ============================================================================
# Data Upload Lambda Execution Role
# ============================================================================

resource "aws_iam_role" "data_upload_lambda" {
  name = "${local.name_prefix}-data-upload-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-data-upload-lambda-role"
    }
  )
}

resource "aws_iam_role_policy" "data_upload_lambda_dynamodb" {
  name = "DynamoDBAccess"
  role = aws_iam_role.data_upload_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ]
        Resource = [
          var.sensor_table_arn,
          var.event_table_arn,
          var.device_state_table_arn,
          var.participant_table_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "data_upload_lambda_s3" {
  name = "S3Access"
  role = aws_iam_role.data_upload_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${var.data_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.data_bucket_arn
      }
    ]
  })
}

# ============================================================================
# Data Upload Lambda Function
# ============================================================================

resource "aws_lambda_function" "data_upload" {
  function_name = "${local.name_prefix}-data-upload"
  role          = aws_iam_role.data_upload_lambda.arn
  runtime       = var.lambda_runtime
  handler       = "data_upload_handler.lambda_handler"
  timeout       = var.lambda_timeout
  memory_size   = var.data_upload_lambda_memory

  filename         = "${path.module}/placeholder.zip"
  source_code_hash = filebase64sha256("${path.module}/placeholder.zip")

  environment {
    variables = {
      SENSOR_TABLE_NAME       = var.sensor_table_name
      EVENT_TABLE_NAME        = var.event_table_name
      DEVICE_STATE_TABLE_NAME = var.device_state_table_name
      PARTICIPANT_TABLE_NAME  = var.participant_table_name
      DATA_BUCKET_NAME        = var.data_bucket_name
      ENVIRONMENT             = var.environment
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-data-upload"
    }
  )

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      last_modified
    ]
  }
}

resource "aws_cloudwatch_log_group" "data_upload_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.data_upload.function_name}"
  retention_in_days = var.lambda_log_retention

  tags = var.tags
}
