data "aws_caller_identity" "this" {}

data "aws_partition" "current" {}

data "aws_region" "this" {}

# ----------------------------------------------------------------------------
# Terminate Instances - IAM Resources
# ----------------------------------------------------------------------------

################################################################################
### ASG IAM
################################################################################

data "aws_iam_policy_document" "asg_lifecycle_assume_role" {
  count = var.graceful_terminate_enabled ? 1 : 0

  statement {
    actions = [
      "sts:AssumeRole",
    ]
    effect = "Allow"

    principals {
      identifiers = ["autoscaling.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "asg_lifecycle" {
  count = var.graceful_terminate_enabled ? 1 : 0

  name                  = "${var.name_iam_objects}-${var.name}-asg-lifecycle"
  description           = "Role for the graceful terminate ASG lifecycle hook"
  path                  = "/"
  permissions_boundary  = var.role_permissions_boundary
  assume_role_policy    = data.aws_iam_policy_document.asg_lifecycle_assume_role[0].json
  force_detach_policies = true
  tags                  = var.tags
}

# This IAM policy is used by the ASG lifecycle hook.
data "aws_iam_policy_document" "asg_lifecycle" {
  count = var.graceful_terminate_enabled ? 1 : 0

  # Permit the GitLab Runner ASG to send messages to SQS
  statement {
    sid = "ASGLifecycleSqs"
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueUrl"
    ]
    resources = ["${aws_sqs_queue.graceful_terminate_queue[0].arn}"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "asg_lifecycle" {
  count = var.graceful_terminate_enabled ? 1 : 0

  name   = "${var.name_iam_objects}-${var.name}-asg-lifecycle"
  path   = "/"
  policy = data.aws_iam_policy_document.asg_lifecycle[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "asg_lifecycle" {
  count = var.graceful_terminate_enabled ? 1 : 0

  role       = aws_iam_role.asg_lifecycle[0].name
  policy_arn = aws_iam_policy.asg_lifecycle[0].arn
}

################################################################################
### Lambda IAM
################################################################################

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "lambda" {
  name                  = "${var.name_iam_objects}-${var.name}"
  description           = "Role for executing the ${var.name} instance termination function"
  path                  = "/"
  permissions_boundary  = var.role_permissions_boundary
  assume_role_policy    = data.aws_iam_policy_document.assume_role.json
  force_detach_policies = true
  tags                  = var.tags
}


# This IAM policy is used by the Lambda function.
data "aws_iam_policy_document" "lambda" {
  # checkov:skip=CKV_AWS_111:Write access is limited to the resources needed

  # Permit the function to get a list of instances
  statement {
    sid = "GitLabRunnerLifecycleGetInstances"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:DescribeRegions",
      "ec2:DescribeInstanceStatus",
    ]
    resources = ["*"]
    effect    = "Allow"
  }

  # Permit the function to terminate instances with the 'gitlab-runner-parent-id'
  # tag.
  statement {
    sid = "GitLabRunnerLifecycleTerminateInstances"
    actions = [
      "ec2:TerminateInstances"
    ]
    resources = ["arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:instance/*"]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/gitlab-runner-parent-id"
      values   = ["i-*"]
    }
    effect = "Allow"
  }

  # Permit the function to execute the ASG lifecycle action
  statement {
    sid    = "GitLabRunnerLifecycleTerminateEvent"
    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction"
    ]
    resources = [var.asg_arn]
  }

  statement {
    sid = "GitLabRunnerLifecycleTerminateLogs"
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
    ]
    effect = "Allow"
    # wildcard resources are ok as the log streams are created dynamically during runtime and are not known here
    # tfsec:ignore:aws-iam-no-policy-wildcards
    resources = [
      aws_cloudwatch_log_group.lambda.arn,
      "${aws_cloudwatch_log_group.lambda.arn}:log-stream:*"
    ]
  }

  statement {
    sid = "SSHKeyHousekeepingList"

    effect = "Allow"
    actions = [
      "ec2:DescribeKeyPairs"
    ]
    resources = ["*"]
  }

  # separate statement due to the condition
  statement {
    sid = "SSHKeyHousekeepingDelete"

    effect = "Allow"
    actions = [
      "ec2:DeleteKeyPair"
    ]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "ec2:KeyPairName"
      values   = ["runner-*"]
    }
  }
}

data "aws_iam_policy_document" "spot_request_housekeeping" {
  # checkov:skip=CKV_AWS_111:I didn't found any condition to limit the access.
  # checkov:skip=CKV_AWS_356:False positive and fixed with version 2.3.293
  statement {
    sid = "SpotRequestHousekeepingList"

    effect = "Allow"
    actions = [
      "ec2:CancelSpotInstanceRequests",
      "ec2:DescribeSpotInstanceRequests"
    ]
    # I didn't found any condition to limit the access
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "graceful_terminate" {
  count = var.graceful_terminate_enabled ? 1 : 0

  # Permit the function to process SQS messages
  statement {
    sid = "GitLabRunnerGracefulTerminateSQS"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage"
    ]
    effect = "Allow"
    resources = [
      resource.aws_sqs_queue.graceful_terminate_queue[0].arn
    ]
  }

  # Permit the function to invoke the SSM document for stopping gitlab-runner
  statement {
    sid = "GitLabRunnerGracefulTerminateSSMSend"
    actions = [
      "ssm:SendCommand"
    ]
    effect = "Allow"
    resources = [
      resource.aws_ssm_document.stop_gitlab_runner[0].arn
    ]
  }

  # Permit the function to send SSM commands to the GitLab Runner instance
  statement {
    sid = "GitLabRunnerGracefulTerminateSSMSendEC2"
    actions = [
      "ssm:SendCommand"
    ]
    effect = "Allow"
    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:instance/*"
    ]
    condition {
      test     = "StringLike"
      variable = "ssm:ResourceTag/Name"
      values   = ["${var.environment}*"]
    }
  }

  # Permit the function to get SSM command invocation details
  statement {
    sid = "GitLabRunnerGracefulTerminateSSMGet"
    actions = [
      "ssm:GetCommandInvocation"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "lambda" {
  name   = "${var.name_iam_objects}-${var.name}-lambda"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_iam_policy" "spot_request_housekeeping" {
  name   = "${var.name_iam_objects}-${var.name}-cancel-spot"
  path   = "/"
  policy = data.aws_iam_policy_document.spot_request_housekeeping.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "spot_request_housekeeping" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.spot_request_housekeeping.arn
}

resource "aws_iam_policy" "graceful_terminate" {
  count = var.graceful_terminate_enabled ? 1 : 0

  name   = "${var.name_iam_objects}-${var.name}-graceful-terminate"
  path   = "/"
  policy = data.aws_iam_policy_document.graceful_terminate[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "graceful_terminate" {
  count = var.graceful_terminate_enabled ? 1 : 0

  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.graceful_terminate[0].arn
}
