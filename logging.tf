resource "aws_iam_role_policy" "instance" {
  count  = var.runner_cloudwatch.enable && var.runner_role.create_role_profile ? 1 : 0
  name   = "${local.name_iam_objects}-logging"
  role   = var.runner_role.create_role_profile ? aws_iam_role.instance[0].name : local.aws_iam_role_instance_name
  policy = templatefile("${path.module}/policies/instance-logging-policy.json", { partition = data.aws_partition.current.partition })
}

locals {
  logging_user_data = templatefile("${path.module}/template/logging.tftpl",
    {
      log_group_name = var.runner_cloudwatch.log_group_name != null ? var.runner_cloudwatch.log_group_name : var.environment
  })
  provided_kms_key = var.kms_key_id != "" ? var.kms_key_id : ""
  kms_key          = local.provided_kms_key == "" && var.enable_managed_kms_key ? aws_kms_key.default[0].arn : local.provided_kms_key
}

resource "aws_cloudwatch_log_group" "environment" {
  count = var.runner_cloudwatch.enable ? 1 : 0
  name  = var.runner_cloudwatch.log_group_name != null ? var.runner_cloudwatch.log_group_name : var.environment
  # ignores a false positive: retention_in_days not set
  # kics-scan ignore-line
  retention_in_days = var.runner_cloudwatch.retention_days
  tags              = local.tags

  # ignored as decided by the user
  # tfsec:ignore:aws-cloudwatch-log-group-customer-key
  # checkov:skip=CKV_AWS_158:Encryption can be enabled by user
  kms_key_id = local.kms_key
}
