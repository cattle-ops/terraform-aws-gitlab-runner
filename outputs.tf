output "runner_as_group_name" {
  description = "Name of the autoscaling group for the gitlab-runner instance"
  value       = "${aws_autoscaling_group.gitlab_runner_instance.name}"
}

output "runner_cache_bucket_arn" {
  description = "ARN of the S3 for the build cache."
  value       = "${aws_s3_bucket.build_cache.arn}"
}
