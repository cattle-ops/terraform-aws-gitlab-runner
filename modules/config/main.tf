locals {
  cloudtrail_name = "${var.name}-config-trail"

  cloudtrail_prefix      = var.cloudtrail_prefix == "" ? "gitlab-runner-config" : var.cloudtrail_prefix
  cloudtrail_bucket      = length(var.cloudtrail_bucket) > 0 ? data.aws_s3_bucket.cloudtrail[0].bucket : "${var.name}-cloudtrail"
  cloudtrail_bucket_name = length(var.cloudtrail_bucket) > 0 ? data.aws_s3_bucket.cloudtrail[0].bucket : aws_s3_bucket.cloudtrail[0].bucket
  cloudtrail_bucket_arn  = "arn:aws:s3:::${local.cloudtrail_bucket}"

  config_key         = var.config_key == "" ? "config.toml" : var.config_key
  config_bucket      = length(var.config_bucket) > 0 ? data.aws_s3_bucket.config[0].bucket : "${var.name}-config"
  config_bucket_name = length(var.cloudtrail_bucket) > 0 ? data.aws_s3_bucket.config[0].bucket : aws_s3_bucket.config[0].bucket
  config_bucket_arn  = "arn:aws:s3:::${local.config_bucket}"

  extra_files_prefix = trim(var.extra_files_prefix == "" ? "/extra-files/" : var.extra_files_prefix, "/")

  config_uri      = "s3://${aws_s3_bucket_object.config.bucket}/${aws_s3_bucket_object.config.key}"
  extra_files_uri = "s3://${aws_s3_bucket_object.config.bucket}/${local.extra_files_prefix}"

  post_reload_script = length(var.post_reload_script) > 0 ? "echo \"Executing post_reload_config script...\"\n${var.post_reload_script}" : ""
}

data "aws_region" "current" {}

################################################################################
### Create config bucket & save config.toml there
################################################################################

data "aws_s3_bucket" "config" {
  count  = var.config_bucket == "" ? 0 : 1
  bucket = var.config_bucket
}

resource "aws_s3_bucket" "config" {
  count = var.config_bucket == "" ? 1 : 0

  bucket        = local.config_bucket
  acl           = "private"
  tags          = var.tags
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "aws_iam_policy_document" "config_bucket" {
  statement {
    sid    = "AllowGitLabRunnerAccessData"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectAcl",
    ]
    resources = [
      "${local.config_bucket_arn}/${local.config_key}",
      "${local.config_bucket_arn}/${local.extra_files_prefix}/*",
    ]
  }
  statement {
    sid    = "AllowGitLabRunnerListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [local.config_bucket_arn]
  }
}

resource "aws_iam_policy" "config_bucket" {
  name        = "${var.name}-config-bucket"
  description = "Policy for Gitlab Runner EC2 instance to access configuration"

  policy = data.aws_iam_policy_document.config_bucket.json
}

resource "aws_s3_bucket_object" "config" {
  bucket  = local.config_bucket_name
  key     = local.config_key
  content = var.config_content
  acl     = "private"
  tags    = var.tags
}

resource "aws_s3_bucket_object" "extra_files" {
  for_each = var.extra_files

  bucket  = local.config_bucket_name
  key     = "${local.extra_files_prefix}/${each.key}"
  content = each.value
  acl     = "private"
  tags    = var.tags
}

locals {
  extra_files_sync_command = "mkdir -p /extra-files && aws s3 cp ${local.extra_files_uri} /extra-files --recursive"
}

################################################################################
### Create CloudTrail trail in order to monitor configuration changes
### and react to them by running SSM Command on Gitlab runner manager instance.
################################################################################

data "aws_s3_bucket" "cloudtrail" {
  count  = var.cloudtrail_bucket == "" ? 0 : 1
  bucket = var.cloudtrail_bucket
}

resource "aws_s3_bucket" "cloudtrail" {
  count  = var.config_bucket == "" ? 1 : 0
  bucket = local.cloudtrail_bucket

  policy        = data.aws_iam_policy_document.cloudtrail_bucket.json
  acl           = "private"
  tags          = var.tags
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid       = "AWSCloudTrailAclCheck"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [local.cloudtrail_bucket_arn]

    principals {
      identifiers = ["cloudtrail.amazonaws.com"]
      type        = "Service"
    }
  }

  statement {
    sid     = "AWSCloudTrailWrite"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${local.cloudtrail_bucket_arn}/${local.cloudtrail_prefix}/AWSLogs/*"
    ]

    condition {
      test     = "StringEquals"
      values   = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }

    principals {
      identifiers = ["cloudtrail.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudtrail" "cloudtrail" {
  name           = local.cloudtrail_name
  s3_bucket_name = local.cloudtrail_bucket
  s3_key_prefix  = local.cloudtrail_prefix
  enable_logging = true

  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${local.config_bucket_arn}/"]
    }
  }
}

data "aws_iam_policy_document" "config_update_ssm_command_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "config_update_ssm_command" {
  depends_on = [var.runner_autoscaling_group_name]

  statement {
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/aws:autoscaling:groupName"
      values   = [var.runner_autoscaling_group_name]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = [aws_ssm_document.reload_config.arn]
  }
}

resource "aws_iam_role" "config_update_ssm_command" {
  name               = "${var.name}-config-update"
  assume_role_policy = data.aws_iam_policy_document.config_update_ssm_command_trust.json
}

resource "aws_iam_role_policy" "config_update_ssm_command" {
  role   = aws_iam_role.config_update_ssm_command.name
  name   = "ConfigUpdateSSMCommand"
  policy = data.aws_iam_policy_document.config_update_ssm_command.json
}

resource "aws_ssm_document" "reload_config" {
  name          = "${var.name}-reload-gitlab-configuration"
  target_type   = "/AWS::EC2::Instance"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Reload Gitlab Configuration."
    parameters    = {},
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "reloadGitlabConfiguration"
        inputs = {
          timeoutSeconds = "60"
          runCommand = [
            <<-EOF
              echo "Validating Gitlab installation..."
              hash jq gitlab-runner >/dev/null || {
                echo "Runner is not ready yet, skipping update, as runner should pull configuration automatically on boot."
                exit 0
              }
              echo "Pulling Gitlab token from SSM parameters..."
              token=$(aws ssm get-parameters --names "${var.gitlab_token_ssm_key}" --with-decryption --region "${data.aws_region.current.name}" | jq -r ".Parameters | .[0] | .Value")

              echo "Pulling file from S3 bucket..."
              config_file="/etc/gitlab-runner/config.toml"
              aws s3 cp "${local.config_uri}" "$${config_file}"

              echo "Replacing tokens in configuration with stored Gitlab token..."
              sed -i.bak s/__REPLACED_BY_USER_DATA__/`echo $token`/g "$${config_file}"

              echo "Pulling extra files from S3 bucket (if any)..."
              ${local.extra_files_sync_command}

              ${var.post_reload_script}

              echo "Restarting GitLab runner..."
              gitlab-runner restart
            EOF
          ]
        }
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "config_changes" {
  name        = "${var.name}-config-changes"
  description = "Watch configuration changes for Gitlab runner."

  event_pattern = jsonencode({
    source = ["aws.s3"]
    detail = {
      eventSource = ["s3.amazonaws.com"]
      eventName   = ["PutObject", "CompleteMultipartUpload"]
      requestParameters = {
        bucketName = [aws_s3_bucket_object.config.bucket]
        key = concat([aws_s3_bucket_object.config.key], [
          for file in aws_s3_bucket_object.extra_files : file.key
        ])
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "reload_config" {
  depends_on = [var.runner_autoscaling_group_name]

  target_id = "ReloadGitlabConfig"
  arn       = aws_ssm_document.reload_config.arn
  rule      = aws_cloudwatch_event_rule.config_changes.name
  role_arn  = aws_iam_role.config_update_ssm_command.arn

  run_command_targets {
    key    = "tag:aws:autoscaling:groupName"
    values = [var.runner_autoscaling_group_name]
  }

}
