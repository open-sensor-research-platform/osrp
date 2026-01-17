# ============================================================================
# Cognito Module
# ============================================================================

locals {
  name_prefix = "${var.study_name}-${var.environment}"
}

# ============================================================================
# User Pool
# ============================================================================

resource "aws_cognito_user_pool" "main" {
  name = "${local.name_prefix}-users"

  # Username configuration
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  # Custom attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    name                = "studyCode"
    attribute_data_type = "String"
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 256
    }
  }

  schema {
    name                = "participantId"
    attribute_data_type = "String"
    mutable             = false

    string_attribute_constraints {
      min_length = 0
      max_length = 256
    }
  }

  # Password policy
  password_policy {
    minimum_length                   = var.password_minimum_length
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  # Email verification
  email_verification_message = "Your OSRP verification code is {####}"
  email_verification_subject = "Verify your OSRP account"

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # MFA configuration
  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # User attribute update settings
  user_attribute_update_settings {
    attributes_require_verification_before_update = ["email"]
  }

  # Device tracking
  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = false
  }

  # Admin create user config
  admin_create_user_config {
    allow_admin_create_user_only = false

    invite_message_template {
      email_message = "Welcome to OSRP! Your username is {username} and temporary password is {####}"
      email_subject = "Welcome to OSRP Study"
      sms_message   = "Your OSRP username is {username} and temporary password is {####}"
    }
  }

  # Deletion protection
  deletion_protection = var.enable_deletion_protection ? "ACTIVE" : "INACTIVE"

  tags = merge(
    var.tags,
    {
      Name    = "${local.name_prefix}-users"
      Purpose = "Authentication"
    }
  )
}

# ============================================================================
# User Pool Client
# ============================================================================

resource "aws_cognito_user_pool_client" "mobile" {
  name         = "${local.name_prefix}-mobile-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # Authentication flows
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  # Token validity
  refresh_token_validity = var.token_validity_refresh
  access_token_validity  = var.token_validity_access
  id_token_validity      = var.token_validity_id

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Read/write attributes
  read_attributes = [
    "email",
    "email_verified",
    "custom:studyCode",
    "custom:participantId"
  ]

  write_attributes = [
    "email",
    "custom:studyCode"
  ]
}

# ============================================================================
# User Pool Domain
# ============================================================================

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.study_name}-${var.environment}-${var.account_id}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# ============================================================================
# Identity Pool
# ============================================================================

resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${var.study_name}_identity_pool_${var.environment}"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.mobile.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = false
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-identity-pool"
    }
  )
}

# ============================================================================
# IAM Role for Authenticated Users
# ============================================================================

resource "aws_iam_role" "cognito_authenticated" {
  name = "${local.name_prefix}-cognito-authenticated"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonCognitoPowerUser"
  ]

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-cognito-authenticated"
    }
  )
}

# ============================================================================
# Identity Pool Role Attachment
# ============================================================================

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    authenticated = aws_iam_role.cognito_authenticated.arn
  }
}
