# Module to manage configuration file.

This module manages config on S3 bucket and automatically reflects changes after pushing new config contents. To achieve it, a couple of additional resources have to be created besides S3 bucket, IAM policy and config object:
- CloudTrail trail,
- CloudTrail bucket,
- SSM Document,
- CloudWatch event configuration.
