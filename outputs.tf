output "lambda_iam_role_arn" {
  description = "The ARN of the lambda IAM role"
  value       = aws_iam_role.this.arn
}

output "lambda_iam_role_name" {
  description = "The name of the lambda IAM role"
  value       = aws_iam_role.this.name
}

output "lambda_arn" {
  description = "The ARN of the lambda function"
  value       = aws_lambda_function.this.arn
}

output "lambda_name" {
  description = "The name of the lambda function"
  value       = aws_lambda_function.this.function_name
}

output "lambda_invoke_arn" {
  description = "The invoke ARN of the lambda function"
  value       = aws_lambda_function.this.invoke_arn
}

output "log_group_arn" {
  description = "The ARN of the log group"
  value       = aws_cloudwatch_log_group.this.arn
}

output "log_group_name" {
  description = "The name of the log group"
  value       = aws_cloudwatch_log_group.this.name
}
