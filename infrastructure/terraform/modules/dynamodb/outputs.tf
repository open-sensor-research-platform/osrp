output "participant_status_table_name" {
  description = "ParticipantStatus table name"
  value       = aws_dynamodb_table.participant_status.name
}

output "participant_status_table_arn" {
  description = "ParticipantStatus table ARN"
  value       = aws_dynamodb_table.participant_status.arn
}

output "sensor_time_series_table_name" {
  description = "SensorTimeSeries table name"
  value       = aws_dynamodb_table.sensor_time_series.name
}

output "sensor_time_series_table_arn" {
  description = "SensorTimeSeries table ARN"
  value       = aws_dynamodb_table.sensor_time_series.arn
}

output "event_log_table_name" {
  description = "EventLog table name"
  value       = aws_dynamodb_table.event_log.name
}

output "event_log_table_arn" {
  description = "EventLog table ARN"
  value       = aws_dynamodb_table.event_log.arn
}

output "device_state_table_name" {
  description = "DeviceState table name"
  value       = aws_dynamodb_table.device_state.name
}

output "device_state_table_arn" {
  description = "DeviceState table ARN"
  value       = aws_dynamodb_table.device_state.arn
}
