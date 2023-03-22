resource "aws_kms_key" "default" {
  count = var.enable_managed_kms_key ? 1 : 0

  description             = "GitLab Runner module managed key - ${var.environment}"
  deletion_window_in_days = var.kms_managed_deletion_rotation_window_in_days > 0 ? var.kms_managed_deletion_rotation_window_in_days : null
  enable_key_rotation     = var.kms_managed_deletion_rotation_window_in_days > 0 ? true : false
  tags                    = local.tags
  policy = templatefile("${path.module}/policies/kms-policy.json",
    {
      partition  = data.aws_partition.current.partition
      aws_region = data.aws_region.current.name
      account_id = data.aws_caller_identity.current.account_id
    }
  )
}

resource "aws_kms_alias" "default" {
  count         = var.enable_managed_kms_key && var.kms_managed_alias_name != "" ? 1 : 0
  name          = "alias/${var.kms_managed_alias_name}"
  target_key_id = aws_kms_key.default[0].key_id
}
