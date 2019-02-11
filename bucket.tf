data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "build_cache" {
  bucket = "${var.cache_bucket_prefix}${data.aws_caller_identity.current.account_id}-gitlab-runner-cache"
  acl    = "private"

  tags = "${local.tags}"

  force_destroy = true

  versioning {
    enabled = false
  }

  lifecycle_rule {
    id      = "clear"
    enabled = true

    prefix = "runner/"

    expiration {
      days = "${var.cache_expiration_days}"
    }
  }
}
