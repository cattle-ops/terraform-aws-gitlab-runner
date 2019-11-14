resource "aws_kms_key" "default" {
  count = var.enable_kms ? 1 : 0

  description             = "GitLab Runner module managed key - ${var.environment}"
  deletion_window_in_days = var.kms_deletion_window_in_days > 0 ? var.kms_deletion_window_in_days : null
  enable_key_rotation     = var.kms_deletion_window_in_days > 0 ? true : false
  tags                    = local.tags
  policy                  = data.template_file.kms_policy[0].rendered
}

data "template_file" "kms_policy" {
  count = var.enable_kms ? 1 : 0

  template = file("${path.module}/policies/kms-policy.json")

  vars = {
    aws_region = var.aws_region
    account_id = data.aws_caller_identity.current.account_id
  }
}


