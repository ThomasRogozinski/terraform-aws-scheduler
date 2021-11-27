output "lambda_invoke_arn" {
  description = "The invoke ARN of the lambda function"
  value       = module.office-hours-scheduler.lambda_invoke_arn
}
