# Example - AWS Fleeting Plugin - Docker

This example shows how to deploy a GitLab Runner using the [AWS Fleeting Plugin](https://docs.gitlab.com/runner/configuration/autoscale.html)
with Docker and spot instances.

This examples shows:

- You can log into the instance via SSM (Session Manager).
- register the Runner manually in GitLab
- Auto scaling using AWS Fleeting Plugin.

Multi region deployment is, of course, possible. Just instantiate the module multiple times with different AWS providers. In case
you use the cache, make sure to have one cache per region.

## Prerequisite

The Terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please
check `.terraform-version` for the tested version.

<!-- markdownlint-disable -->
<!-- cSpell:disable -->
<!-- markdown-link-check-disable -->

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
