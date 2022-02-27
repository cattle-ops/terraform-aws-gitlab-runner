locals {
  name_iam_objects_main_region         = "${var.aws_main_region}-my-runner-iam-objects"
  cache_bucket_prefix_main_region      = "${var.aws_main_region}-my-runner-cache-bucket"
  name_iam_objects_alternate_region    = "${var.aws_alternate_region}-my-runner-iam-objects"
  cache_bucket_prefix_alternate_region = "${var.aws_alternate_region}-my-runner-cache-bucket"
}