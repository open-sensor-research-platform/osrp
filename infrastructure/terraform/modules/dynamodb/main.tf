# ============================================================================
# DynamoDB Tables Module
# ============================================================================

locals {
  table_prefix = "${var.study_name}-${var.environment}"
}

# ============================================================================
# ParticipantStatus Table
# ============================================================================

resource "aws_dynamodb_table" "participant_status" {
  name         = "${local.table_prefix}-ParticipantStatus"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "groupCode"
    type = "S"
  }

  attribute {
    name = "lastSeenTimestamp"
    type = "N"
  }

  global_secondary_index {
    name            = "groupCode-lastSeen-index"
    hash_key        = "groupCode"
    range_key       = "lastSeenTimestamp"
    projection_type = "ALL"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled = var.enable_encryption
  }

  tags = merge(
    var.tags,
    {
      Name    = "${local.table_prefix}-ParticipantStatus"
      Purpose = "Participant tracking"
    }
  )
}

# ============================================================================
# SensorTimeSeries Table
# ============================================================================

resource "aws_dynamodb_table" "sensor_time_series" {
  name         = "${local.table_prefix}-SensorTimeSeries"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userIdSensorType"
  range_key    = "timestamp"

  attribute {
    name = "userIdSensorType"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "groupCode"
    type = "S"
  }

  global_secondary_index {
    name            = "groupCode-timestamp-index"
    hash_key        = "groupCode"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expirationTime"
    enabled        = true
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled = var.enable_encryption
  }

  tags = merge(
    var.tags,
    {
      Name    = "${local.table_prefix}-SensorTimeSeries"
      Purpose = "Sensor time series data"
    }
  )
}

# ============================================================================
# EventLog Table
# ============================================================================

resource "aws_dynamodb_table" "event_log" {
  name         = "${local.table_prefix}-EventLog"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "timestampEventType"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "timestampEventType"
    type = "S"
  }

  attribute {
    name = "groupCode"
    type = "S"
  }

  attribute {
    name = "eventType"
    type = "S"
  }

  global_secondary_index {
    name            = "groupCode-eventType-index"
    hash_key        = "groupCode"
    range_key       = "eventType"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expirationTime"
    enabled        = true
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled = var.enable_encryption
  }

  tags = merge(
    var.tags,
    {
      Name    = "${local.table_prefix}-EventLog"
      Purpose = "Event logging"
    }
  )
}

# ============================================================================
# DeviceState Table
# ============================================================================

resource "aws_dynamodb_table" "device_state" {
  name         = "${local.table_prefix}-DeviceState"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "timestamp"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "groupCode"
    type = "S"
  }

  global_secondary_index {
    name            = "groupCode-timestamp-index"
    hash_key        = "groupCode"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expirationTime"
    enabled        = true
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled = var.enable_encryption
  }

  tags = merge(
    var.tags,
    {
      Name    = "${local.table_prefix}-DeviceState"
      Purpose = "Device state tracking"
    }
  )
}
