data "aws_caller_identity" "current" {
  count = var.create_cache_bucket ? 1 : 0
}

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

  cache_bucket_name = var.cache_bucket_name_include_account_id ? "${var.cache_bucket_prefix}${data.aws_caller_identity.current[0].account_id}-gitlab-runner-cache" : "${var.cache_bucket_prefix}-gitlab-runner-cache"
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
    enabled = true

    prefix = "runner/"

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

data "template_file" "docker_machine_cache_policy" {
  count = var.create_cache_bucket ? 1 : 0

  template = file("${path.module}/policies/cache.json")

  vars = {
    s3_cache_arn = aws_s3_bucket.build_cache[0].arn
  }
}

resource "aws_iam_policy" "docker_machine_cache" {
  count = var.create_cache_bucket ? 1 : 0

  name        = "${var.environment}-docker-machine-cache"
  path        = "/"
  description = "Policy for docker machine instance to access cache"

  policy = data.template_file.docker_machine_cache_policy[0].rendered
}

