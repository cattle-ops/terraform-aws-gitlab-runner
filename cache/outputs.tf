output "policy_arn" {
  value = "${element(concat(aws_iam_policy.docker_machine_cache.*.arn, list("")), 0)}"
}

output "bucket" {
  value = "${element(concat(aws_s3_bucket.build_cache.*.bucket, list("")), 0)}"
}
