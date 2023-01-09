data "aws_partition" "current" {}
data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

# ----------------------------------------------------------------------------
# Terminate Instances - IAM Resources
# ----------------------------------------------------------------------------

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

  statement {
    sid = "SSHKeyHousekeeping"

    effect = "Allow"
    actions = [
      "ec2:DescribeKeyPairs",
      "ec2:DeleteKeyPair"
    ]
    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ec2:${data.aws_region.this.id}:${data.aws_caller_identity.this.account_id}:key-pair/runner-*"]
    }
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
}

data "aws_iam_policy_document" "ssh_key_housekeeping" {
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

resource "aws_iam_policy" "lambda" {
  name   = "${var.name_iam_objects}-${var.name}-lambda"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda.json

  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_iam_policy" "ssh_key_housekeeping" {
  name   = "${var.name_iam_objects}-${var.name}-ssh-key"
  path   = "/"
  policy = data.aws_iam_policy_document.ssh_key_housekeeping.json

  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "ssh_key_housekeeping" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.ssh_key_housekeeping.arn
}