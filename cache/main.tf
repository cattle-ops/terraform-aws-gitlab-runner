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
}

resource "aws_s3_bucket" "build_cache" {
  count = var.create_cache_bucket ? 1 : 0

  bucket = "${var.cache_bucket_prefix}${data.aws_caller_identity.current[0].account_id}-gitlab-runner-cache"
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

