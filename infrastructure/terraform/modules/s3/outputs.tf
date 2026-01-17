output "data_bucket_name" {
  description = "Data bucket name"
  value       = aws_s3_bucket.data.id
}

output "data_bucket_arn" {
  description = "Data bucket ARN"
  value       = aws_s3_bucket.data.arn
}

output "logging_bucket_name" {
  description = "Logging bucket name"
  value       = aws_s3_bucket.logging.id
}

output "logging_bucket_arn" {
  description = "Logging bucket ARN"
  value       = aws_s3_bucket.logging.arn
}
