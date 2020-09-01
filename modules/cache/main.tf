data "aws_caller_identity" "current" {}


locals {
  tags = merge(
    {
      "Name" = format("%s", var.environment)
    },
    {
      "Environment" = format("%s", var.environment)
    },
    var.tags,
  )

  cache_bucket_prefix = var.cache_bucket_name_include_account_id ? "${var.cache_bucket_prefix}${data.aws_caller_identity.current.account_id}-gitlab-runner-cache" : "${var.cache_bucket_prefix}-gitlab-runner-cache"
  cache_bucket_name   = var.cache_bucket_set_suffix ? format("%s-%s", local.cache_bucket_prefix, random_string.s3_suffix.result) : local.cache_bucket_prefix
}

resource "random_string" "s3_suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "aws_s3_bucket" "build_cache" {
  count = var.create_cache_bucket ? 1 : 0

  bucket = local.cache_bucket_name
  acl    = "private"

  tags = local.tags

  force_destroy = true

  versioning {
    enabled = var.cache_bucket_versioning
  }

  lifecycle_rule {
    id      = "clear"
    enabled = var.cache_lifecycle_clear

    prefix = var.cache_lifecycle_prefix

    expiration {
      days = var.cache_expiration_days
    }

    noncurrent_version_expiration {
      days = var.cache_expiration_days
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_iam_policy" "docker_machine_cache" {
  count = var.create_cache_bucket ? 1 : 0

  name        = "${var.environment}-docker-machine-cache"
  path        = "/"
  description = "Policy for docker machine instance to access cache"

  policy = templatefile("${path.module}/policies/cache.json",
    {
      s3_cache_arn = var.create_cache_bucket == false || length(aws_s3_bucket.build_cache) == 0 ? "${var.arn_format}:s3:::fake_bucket_doesnt_exist" : aws_s3_bucket.build_cache[0].arn
    }
  )
}
