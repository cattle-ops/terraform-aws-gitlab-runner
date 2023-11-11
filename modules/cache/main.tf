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

  cache_bucket_string = var.cache_bucket_name_include_account_id ? format("%s-%s%s-gitlab-runner-cache", var.environment, var.cache_bucket_prefix, data.aws_caller_identity.current.account_id) : format("%s-%s-gitlab-runner-cache", var.environment, var.cache_bucket_prefix)
  cache_bucket_name   = var.cache_bucket_set_random_suffix ? format("%s-%s", local.cache_bucket_string, random_string.s3_suffix[0].result) : local.cache_bucket_string

  name_iam_objects = var.name_iam_objects == "" ? local.tags["Name"] : var.name_iam_objects
}

resource "random_string" "s3_suffix" {
  count   = var.cache_bucket_set_random_suffix ? 1 : 0
  length  = 8
  upper   = false
  special = false
}

# ok as user can decide to enable the logging. See aws_s3_bucket_logging resource below.
# tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "build_cache" {
  # checkov:skip=CKV_AWS_21:Versioning can be decided by user
  # checkov:skip=CKV_AWS_144:It's a cache only. Replication not needed.
  # checkov:skip=CKV2_AWS_62:It's a simple cache. We don't want to notify anyone.
  bucket = local.cache_bucket_name

  tags = local.tags

  force_destroy = true
}

resource "aws_s3_bucket_versioning" "build_cache_versioning" {
  bucket = aws_s3_bucket.build_cache.id

  versioning_configuration {
    # ok as decided by the user
    # tfsec:ignore:aws-s3-enable-versioning
    # kics-scan ignore-line
    status = var.cache_bucket_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "build_cache_versioning" {
  # checkov:skip=CKV_AWS_300:False positive. Can be removed when https://github.com/bridgecrewio/checkov/issues/4733 is fixed.
  bucket = aws_s3_bucket.build_cache.id

  rule {
    id     = "AbortIncompleteMultipartUploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  rule {
    id     = "clear"
    status = var.cache_lifecycle_clear ? "Enabled" : "Disabled"

    filter {
      prefix = var.cache_lifecycle_prefix
    }

    expiration {
      days = var.cache_expiration_days
    }
  }
}

# decision by user whether to use a customer managed key or not. Resource is encrypted either.
# tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "build_cache_encryption" {
  bucket = aws_s3_bucket.build_cache.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      # ignores a false positive: S3 Bucket SSE Disabled
      # kics-scan ignore-line
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
  }
}

# block public access to S3 cache bucket
resource "aws_s3_bucket_public_access_block" "build_cache_policy" {
  bucket = aws_s3_bucket.build_cache.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_logging" "build_cache" {
  count = var.cache_logging_bucket != null ? 1 : 0

  bucket = aws_s3_bucket.build_cache.id

  target_bucket = var.cache_logging_bucket
  target_prefix = var.cache_logging_bucket_prefix
}

resource "aws_iam_policy" "docker_machine_cache" {
  name        = "${local.name_iam_objects}-docker-machine-cache"
  path        = "/"
  description = "Policy for docker machine instance to access cache"

  tags = local.tags

  policy = templatefile("${path.module}/policies/cache.json",
    {
      s3_cache_arn = aws_s3_bucket.build_cache.arn
    }
  )
}
