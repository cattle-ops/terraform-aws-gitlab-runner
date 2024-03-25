# ----------------------------------------------------------------------------
# Graceful Terminate - SQS Resources
# ----------------------------------------------------------------------------

resource "aws_sqs_queue" "graceful_terminate_dlq" {
  count = var.graceful_terminate_enabled ? 1 : 0

  name                    = "${var.environment}-graceful-terminate-dlq"
  sqs_managed_sse_enabled = true

  tags = var.tags
}

resource "aws_sqs_queue" "graceful_terminate_queue" {
  count = var.graceful_terminate_enabled ? 1 : 0

  name                       = "${var.environment}-graceful-terminate-queue"
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = var.sqs_visibility_timeout
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.graceful_terminate_dlq[0].arn
    maxReceiveCount     = var.sqs_max_receive_count
  })

  tags = var.tags
}
