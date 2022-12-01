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

resource "aws_s3_bucket" "build_cache" {
  bucket = local.cache_bucket_name

  tags = local.tags

  force_destroy = true
}

resource "aws_s3_bucket_acl" "build_cache_acl" {
  bucket = aws_s3_bucket.build_cache.id

  acl = "private"
}

resource "aws_s3_bucket_versioning" "build_cache_versioning" {
  bucket = aws_s3_bucket.build_cache.id

  versioning_configuration {
    status = var.cache_bucket_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "build_cache_versioning" {
  bucket = aws_s3_bucket.build_cache.id

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

resource "aws_s3_bucket_server_side_encryption_configuration" "build_cache_encryption" {
  bucket = aws_s3_bucket.build_cache.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
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

resource "aws_iam_policy" "docker_machine_cache" {
  name        = "${local.name_iam_objects}-docker-machine-cache"
  path        = "/"
  description = "Policy for docker machine instance to access cache"
  tags        = local.tags

  policy = templatefile("${path.module}/policies/cache.json",
    {
      s3_cache_arn = aws_s3_bucket.build_cache.arn
    }
  )
}
