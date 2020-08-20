output "config_iam_policy_arn" {
  value       = aws_iam_policy.config_bucket.arn
  description = "ARN of policy that allows to pull configuration file from S3 bucket."
}

output "config_uri" {
  value       = local.config_uri
  description = "S3 URI to configuration file on configuration bucket. One can pass it to s3 cp command in order to pull it."
}

output "config_bucket" {
  value       = local.config_bucket_name
  description = "Name of Gitlab runner configuration bucket."
}

output "cloudtrail_bucket" {
  value       = local.cloudtrail_bucket_name
  description = "Name of CloudTrail bucket"
}
