output "policy_arn" {
  description = "Policy for users of the cache (bucket)."
  value       = element(concat(aws_iam_policy.docker_machine_cache.*.arn, [""]), 0)
}

output "bucket" {
  description = "Name of the created bucket."
  value       = element(concat(aws_s3_bucket.build_cache.*.bucket, [""]), 0)
}

output "arn" {
  description = "The ARN of the created bucket."
  value       = element(concat(aws_s3_bucket.build_cache.*.arn, [""]), 0)
}

