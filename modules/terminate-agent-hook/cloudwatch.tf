# ----------------------------------------------------------------------------
# Terminate Instances - CloudWatch/EventBridge Resources
#
# This deploys an event rule and target for triggering the provided Lambda
# function from the ASG lifecycle hook.
# ----------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "terminate_instances" {
  name        = "${var.environment}-${var.name}"
  description = "Trigger GitLab runner instance lifecycle hook on termination."

  event_pattern = <<EOF
{
  "source": ["aws.autoscaling"],
  "detail-type": ["EC2 Instance-terminate Lifecycle Action"],
  "detail": {
    "AutoScalingGroupName": ["${var.asg_name}"]
  }
}
EOF

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "terminate_instances" {
  rule      = aws_cloudwatch_event_rule.terminate_instances.name
  target_id = "${var.environment}-TriggerTerminateLambda"
  arn       = aws_lambda_function.terminate_runner_instances.arn
}

resource "aws_cloudwatch_log_group" "lambda" {
  name = "/aws/lambda/${var.environment}-${var.name}"
  # checkov:skip=CKV_AWS_338:There is no need to store the logs for 1+ years. They are not critical.
  retention_in_days = var.cloudwatch_logging_retention_in_days

  # ok as encryption can be activated by the user
  # tfsec:ignore:aws-cloudwatch-log-group-customer-key
  # checkov:skip=CKV_AWS_158:Encryption can be activated by the user
  kms_key_id = var.kms_key_id

  tags = var.tags
}
