output "policy_arn" {
  description = "Policy for users of the cache (bucket)."
  value       = aws_iam_policy.docker_machine_cache.arn
}

output "bucket" {
  description = "Name of the created bucket."
  value       = aws_s3_bucket.build_cache.bucket
}

output "arn" {
  description = "The ARN of the created bucket."
  value       = aws_s3_bucket.build_cache.arn
}

