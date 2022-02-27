# ----------------------------------------------------------------------------
# Terminate Runner Instances Module
#
# Deploys a Lambda function, CloudWatch rule, and associated resources for
# terminating orphaned runner instances.
# ----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

locals {
  source_sha256 = filesha256("${path.module}/lambda/lambda_function.py")
}

data "archive_file" "terminate_runner_instances_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "builds/lambda_function_${local.source_sha256}.zip"
}

resource "aws_lambda_function" "terminate_runner_instances" {
  architectures    = ["x86_64"]
  description      = "Lifecycle hook for terminating GitLab runner instances"
  filename         = data.archive_file.terminate_runner_instances_lambda.output_path
  source_code_hash = data.archive_file.terminate_runner_instances_lambda.output_base64sha256
  function_name    = "${var.environment}-${var.name}"
  handler          = "lambda_function.handler"
  memory_size      = var.lambda_memory_size
  package_type     = "Zip"
  publish          = true
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.9"
  timeout          = var.lambda_timeout
  tags             = var.tags
}

resource "aws_lambda_permission" "current_version_triggers" {
  function_name = aws_lambda_function.terminate_runner_instances.function_name
  qualifier     = aws_lambda_function.terminate_runner_instances.version
  statement_id  = "TerminateInstanceEvent"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.terminate_instances.arn
}

resource "aws_lambda_permission" "unqualified_alias_triggers" {
  function_name = aws_lambda_function.terminate_runner_instances.function_name
  statement_id  = "TerminateInstanceEvent"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.terminate_instances.arn
}

resource "aws_autoscaling_lifecycle_hook" "terminate_instances" {
  name                   = "${var.environment}-${var.name}"
  autoscaling_group_name = var.asg_name
  default_result         = "CONTINUE"
  heartbeat_timeout      = var.lifecycle_heartbeat_timeout
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}