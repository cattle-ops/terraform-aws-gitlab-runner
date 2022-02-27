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

  cache_bucket_string = var.cache_bucket_name_include_account_id ? format("%s%s-gitlab-runner-cache", var.cache_bucket_prefix, data.aws_caller_identity.current.account_id) : format("%s-gitlab-runner-cache", var.cache_bucket_prefix)
  cache_bucket_name   = var.cache_bucket_set_random_suffix ? format("%s-%s", local.cache_bucket_string, random_string.s3_suffix[0].result) : local.cache_bucket_string

  name_iam_objects = var.name_iam_objects == "" ? local.tags["Name"] : var.name_iam_objects
}

resource "random_string" "s3_suffix" {
  count   = var.cache_bucket_set_random_suffix ? 1 : 0
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

# block public access to S3 cache bucket
resource "aws_s3_bucket_public_access_block" "build_cache_policy" {
  count = var.create_cache_bucket ? 1 : 0

  bucket = aws_s3_bucket.build_cache[0].id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_iam_policy" "docker_machine_cache" {
  count = var.create_cache_bucket ? 1 : 0

  name        = "${local.name_iam_objects}-docker-machine-cache"
  path        = "/"
  description = "Policy for docker machine instance to access cache"
  tags        = local.tags

  policy = templatefile("${path.module}/policies/cache.json",
    {
      s3_cache_arn = var.create_cache_bucket == false || length(aws_s3_bucket.build_cache) == 0 ? "${var.arn_format}:s3:::fake_bucket_doesnt_exist" : aws_s3_bucket.build_cache[0].arn
    }
  )
}
