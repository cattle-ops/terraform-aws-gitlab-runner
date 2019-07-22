#!/usr/bin/env bash

echo ---
echo --- Migration state for updates in Release 3.7.0
echo ---
terraform state mv module.runner.aws_s3_bucket.build_cache module.runner.module.cache.aws_s3_bucket.build_cache
terraform state mv module.runner.aws_iam_policy.docker_machine_cache module.runner.module.cache.aws_iam_policy.docker_machine_cache
