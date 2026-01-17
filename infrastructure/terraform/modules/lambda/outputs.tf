output "auth_lambda_name" {
  description = "Auth Lambda function name"
  value       = aws_lambda_function.auth.function_name
}

output "auth_lambda_arn" {
  description = "Auth Lambda function ARN"
  value       = aws_lambda_function.auth.arn
}

output "auth_lambda_invoke_arn" {
  description = "Auth Lambda invoke ARN"
  value       = aws_lambda_function.auth.invoke_arn
}

output "data_upload_lambda_name" {
  description = "Data Upload Lambda function name"
  value       = aws_lambda_function.data_upload.function_name
}

output "data_upload_lambda_arn" {
  description = "Data Upload Lambda function ARN"
  value       = aws_lambda_function.data_upload.arn
}

output "data_upload_lambda_invoke_arn" {
  description = "Data Upload Lambda invoke ARN"
  value       = aws_lambda_function.data_upload.invoke_arn
}
