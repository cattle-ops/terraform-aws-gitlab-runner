locals {
  lambda_handler = var.lambda_handler != null ? var.lambda_handler : "lambda_function.handler"

  replaced_environment_variables = { for key, value in var.environment_variables : key => replace(value, "{HANDLER}", local.lambda_handler) }
}
