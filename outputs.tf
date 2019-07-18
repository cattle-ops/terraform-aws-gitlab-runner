output "runner_as_group_name" {
  description = "Name of the autoscaling group for the gitlab-runner instance"
  value       = aws_autoscaling_group.gitlab_runner_instance.name
}

output "runner_cache_bucket_arn" {
  description = "ARN of the S3 for the build cache."
  value       = module.cache.arn
}

output "runner_agent_role" {
  description = "ARN of the rule used for the ec2 instance for the GitLab runner agent."
  value       = aws_iam_role.instance.arn
}

output "runner_role" {
  description = "ARN of the rule used for the docker machine runners."
  value       = aws_iam_role.docker_machine.arn
}
