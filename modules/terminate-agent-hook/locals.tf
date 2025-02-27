locals {
  original_lambda_handler = "lambda_function.handler"
  lambda_handler          = var.lambda_handler != null ? var.lambda_handler : local.original_lambda_handler

  replaced_environment_variables = { for key, value in var.environment_variables : key => replace(value, "{HANDLER}", local.original_lambda_handler) }
}
