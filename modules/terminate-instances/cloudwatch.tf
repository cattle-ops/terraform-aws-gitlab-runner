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
}

resource "aws_cloudwatch_event_target" "terminate_instances" {
  rule      = aws_cloudwatch_event_rule.terminate_instances.name
  target_id = "${var.environment}-TriggerTerminateLambda"
  arn       = aws_lambda_function.terminate_runner_instances.arn
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.environment}-${var.name}"
  retention_in_days = var.cloudwatch_logging_retention_in_days

  tags = var.tags
}