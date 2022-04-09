# ----------------------------------------------------------------------------
# Terminate Instances - Outputs
# ----------------------------------------------------------------------------

output "lambda_function_arn" {
  description = "Lambda function arn."
  value       = aws_lambda_function.terminate_runner_instances.arn
}

output "lambda_function_invoke_arn" {
  description = "Lambda function invoke arn."
  value       = aws_lambda_function.terminate_runner_instances.invoke_arn
}

output "lambda_function_name" {
  description = "Lambda function name."
  value       = aws_lambda_function.terminate_runner_instances.function_name
}

output "lambda_function_source_code_hash" {
  description = "Lambda function source code hash."
  value       = aws_lambda_function.terminate_runner_instances.source_code_hash
}