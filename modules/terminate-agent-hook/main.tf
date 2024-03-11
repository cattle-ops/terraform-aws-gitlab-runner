# ----------------------------------------------------------------------------
# Terminate Runner Instances Module
#
# Deploys a Lambda function, CloudWatch rule, and associated resources for
# terminating orphaned runner instances.
# ----------------------------------------------------------------------------
locals {
  source_sha256 = filesha256("${path.module}/lambda/lambda_function.py")
}

data "archive_file" "terminate_runner_instances_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "builds/lambda_function_${local.source_sha256}.zip"
}

# tracing functions can be activated by the user
# tfsec:ignore:aws-lambda-enable-tracing
# kics-scan ignore-line
resource "aws_lambda_function" "terminate_runner_instances" {
  #ts:skip=AC_AWS_0485:Tracing functions can be activated by the user
  #ts:skip=AC_AWS_0486 There is no need to run this lambda in our VPC
  # checkov:skip=CKV_AWS_50:Tracing functions can be activated by the user
  # checkov:skip=CKV_AWS_115:We do not assign a reserved concurrency as this function can't be called by users
  # checkov:skip=CKV_AWS_116:We should think about having a dead letter queue for this lambda
  # checkov:skip=CKV_AWS_117:There is no need to run this lambda in our VPC
  # checkov:skip=CKV_AWS_272:Code signing would be a nice enhancement, but I guess we can live without it here
  architectures    = ["x86_64"]
  description      = "Lifecycle hook for terminating GitLab runner agent instances"
  filename         = data.archive_file.terminate_runner_instances_lambda.output_path
  source_code_hash = data.archive_file.terminate_runner_instances_lambda.output_base64sha256
  function_name    = "${var.environment}-${var.name}"
  handler          = "lambda_function.handler"
  memory_size      = 128
  package_type     = "Zip"
  publish          = true
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.11"
  timeout          = var.graceful_terminate_enabled ? local.graceful_terminate_lambda_timeout : local.lambda_timeout
  kms_key_arn      = var.kms_key_id

  tags = var.tags

  environment {
    variables = {
      NAME_EXECUTOR_INSTANCE     = var.name_docker_machine_runners
      GRACEFUL_TERMINATE_ENABLED = var.graceful_terminate_enabled
      DOCUMENT_NAME              = var.graceful_terminate_enabled ? aws_ssm_document.stop_gitlab_runner[0].name : null
      SQS_MAX_RECEIVE_COUNT      = var.sqs_max_receive_count
    }
  }

  dynamic "tracing_config" {
    for_each = var.enable_xray_tracing ? [1] : []

    content {
      mode = "Passthrough"
    }
  }
}

resource "aws_autoscaling_lifecycle_hook" "terminate_instances" {

  name                    = "${var.environment}-${var.name}"
  autoscaling_group_name  = var.asg_name
  default_result          = "CONTINUE"
  heartbeat_timeout       = var.graceful_terminate_enabled ? var.graceful_terminate_timeout : local.lambda_timeout + 20 # allow some extra time for cold starts
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_target_arn = var.graceful_terminate_enabled ? aws_sqs_queue.graceful_terminate_queue[0].arn : null
  role_arn                = var.graceful_terminate_enabled ? aws_iam_role.asg_lifecycle[0].arn : null
}

# use cloudwatch event trigger when graceful terminate is disabled

resource "aws_lambda_permission" "current_version_triggers" {
  count = var.graceful_terminate_enabled ? 0 : 1

  function_name = aws_lambda_function.terminate_runner_instances.function_name
  qualifier     = aws_lambda_function.terminate_runner_instances.version
  statement_id  = "TerminateInstanceEvent"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.terminate_instances[0].arn
}

resource "aws_lambda_permission" "unqualified_alias_triggers" {
  count = var.graceful_terminate_enabled ? 0 : 1

  function_name = aws_lambda_function.terminate_runner_instances.function_name
  statement_id  = "TerminateInstanceEventUnqualified"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.terminate_instances[0].arn
}

# use SQS trigger when graceful terminate is enabled

resource "aws_lambda_function_event_invoke_config" "graceful_terminate" {
  count = var.graceful_terminate_enabled ? 1 : 0

  function_name          = aws_lambda_function.terminate_runner_instances.function_name
  maximum_retry_attempts = 0
}

resource "aws_lambda_event_source_mapping" "graceful_terminate" {
  count = var.graceful_terminate_enabled ? 1 : 0

  event_source_arn = aws_sqs_queue.graceful_terminate_queue[0].arn
  function_name    = aws_lambda_function.terminate_runner_instances.arn
}
