moved {
  from = aws_s3_bucket_public_access_block.build_cache_policy
  to   = aws_s3_bucket_public_access_block.build_cache_policy[0]
}
