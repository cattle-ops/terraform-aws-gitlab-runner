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
  type             = "zip"
  source_file      = "${path.module}/lambda/lambda_function.py"
  output_path      = "builds/lambda_function_${local.source_sha256}.zip"
  output_file_mode = "0666"
}

resource "aws_security_group" "terminate_runner_instances" {
  name        = "${var.environment}-${var.name}"
  description = "Allowing access to external services for the terminate runner instances lambda"

  vpc_id = var.vpc_id

  tags = var.tags
}

resource "aws_vpc_security_group_egress_rule" "docker_autoscaler_egress" {
  for_each = var.egress_rules

  security_group_id = aws_security_group.terminate_runner_instances.id

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  ip_protocol = each.value.protocol

  description                  = each.value.description
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.security_group
  cidr_ipv4                    = each.value.cidr_block
  cidr_ipv6                    = each.value.ipv6_cidr_block

  tags = var.tags
}

# tracing functions can be activated by the user
# tfsec:ignore:aws-lambda-enable-tracing
# kics-scan ignore-line
resource "aws_lambda_function" "terminate_runner_instances" {
  #ts:skip=AC_AWS_0485:Tracing functions can be activated by the user
  # checkov:skip=CKV_AWS_50:Tracing functions can be activated by the user
  # checkov:skip=CKV_AWS_115:We do not assign a reserved concurrency as this function can't be called by users
  # checkov:skip=CKV_AWS_116:We should think about having a dead letter queue for this lambda
  # checkov:skip=CKV_AWS_272:Code signing would be a nice enhancement, but I guess we can live without it here
  architectures    = ["arm64"]
  description      = "Lifecycle hook for terminating GitLab runner agent instances"
  filename         = data.archive_file.terminate_runner_instances_lambda.output_path
  source_code_hash = data.archive_file.terminate_runner_instances_lambda.output_base64sha256
  function_name    = "${var.environment}-${var.name}"
  handler          = local.lambda_handler
  memory_size      = 128
  package_type     = "Zip"
  publish          = true
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.13"
  timeout          = var.timeout
  kms_key_arn      = var.kms_key_id

  layers = [for layer_arn in var.layer_arns : layer_arn]

  environment {
    variables = merge({
      NAME_EXECUTOR_INSTANCE = var.name_docker_machine_runners
    }, local.replaced_environment_variables)
  }

  vpc_config {
    security_group_ids = [aws_security_group.terminate_runner_instances.id]
    subnet_ids         = [var.subnet_id]
  }

  dynamic "tracing_config" {
    for_each = var.enable_xray_tracing ? [1] : []

    content {
      mode = "Passthrough"
    }
  }

  tags = var.tags
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
  statement_id  = "TerminateInstanceEventUnqualified"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.terminate_instances.arn
}

resource "aws_autoscaling_lifecycle_hook" "terminate_instances" {
  name                   = "${var.environment}-${var.name}"
  autoscaling_group_name = var.asg_name
  default_result         = "CONTINUE"
  heartbeat_timeout      = var.asg_hook_terminating_heartbeat_timeout
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}
