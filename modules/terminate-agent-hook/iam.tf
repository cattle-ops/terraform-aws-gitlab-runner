data "aws_caller_identity" "this" {}

data "aws_partition" "current" {}

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

resource "aws_iam_role_policy_attachment" "lambda_kms" {
  count = var.kms_key_id != "" ? 1 : 0

  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_kms[0].arn
}

resource "aws_iam_policy" "lambda_kms" {
  count = var.kms_key_id != "" ? 1 : 0

  name   = "${var.name_iam_objects}-${var.name}-lambda-kms"
  path   = "/"
  policy = data.aws_iam_policy_document.kms_key[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "kms_key" {
  count = var.kms_key_id != "" ? 1 : 0

  # checkov:skip=CKV_AWS_111:Write access is limited to the resources needed
  statement {
    sid = "AllowKmsAccess"
    actions = [
      "kms:Decrypt", # to decrypt the Lambda environment variables
    ]
    resources = [var.kms_key_id]
    effect    = "Allow"
  }
}

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

resource "aws_iam_role_policy_attachment" "aws_lambda_vpc_access_execution_role" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
