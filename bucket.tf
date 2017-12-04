data "aws_caller_identity" "current" {}

output "account_id" {
  value = "${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "build_cache" {
  bucket = "${data.aws_caller_identity.current.account_id}-gitlab-runner-cache"
  acl    = "private"

  tags {
    Name        = "Bucket for runner cache"
    Environment = "${var.environment}"
  }

  force_destroy = true

  versioning {
    enabled = false
  }

  lifecycle_rule {
    id      = "clear"
    enabled = true

    prefix = "runner/"

    expiration {
      days = 1
    }
  }
}

resource "aws_iam_user" "cache_user" {
  name = "${var.cache_user}"
}

resource "aws_iam_access_key" "cache_user" {
  user = "${aws_iam_user.cache_user.name}"
}

data "aws_iam_policy_document" "bucket-policy-doc" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectAcl",
    ]

    principals = {
      type        = "AWS"
      identifiers = ["${aws_iam_user.cache_user.arn}"]
    }

    resources = [
      "${aws_s3_bucket.build_cache.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "bucket-policy" {
  bucket = "${aws_s3_bucket.build_cache.id}"
  policy = "${data.aws_iam_policy_document.bucket-policy-doc.json}"
}
