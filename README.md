<!-- First line should be an H1: Badges on top please! -->
<!-- markdownlint-disable MD041/first-line-heading/first-line-h1 -->
[![Terraform registry](https://img.shields.io/github/v/release/cattle-ops/terraform-aws-gitlab-runner?label=Terraform%20Registry)](https://registry.terraform.io/modules/cattle-ops/gitlab-runner/aws/)
[![Gitter](https://badges.gitter.im/terraform-aws-gitlab-runner/Lobby.svg)](https://gitter.im/terraform-aws-gitlab-runner/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![Actions](https://github.com/cattle-ops/terraform-aws-gitlab-runner/workflows/CI/badge.svg)](https://github.com/cattle-ops/terraform-aws-gitlab-runner/actions)
[![Renovate](https://img.shields.io/badge/renovate-enabled-brightgreen?logo=renovate)](https://www.mend.io/renovate/)
<!-- markdownlint-enable MD041/first-line-heading/first-line-h1 -->

# Terraform module for GitLab auto-scaling runners on AWS spot instances <!-- omit in toc -->

💥 See [issue 819](https://github.com/cattle-ops/terraform-aws-gitlab-runner/issues/819) on how to migrate to v7 smoothly.

This [Terraform](https://www.terraform.io/) modules creates a [GitLab Runner](https://docs.gitlab.com/runner/). A blog post
describes the original version of the runner. See the post at [040code](https://040code.github.io/2017/12/09/runners-on-the-spot/).
The original setup of the module is based on the blog post: [Auto scale GitLab CI runners and save 90% on EC2 costs](https://about.gitlab.com/2017/11/23/autoscale-ci-runners/).

The runners created by the module use spot instances by default for running the builds using the `docker+machine` executor.

- Shared cache in S3 with life cycle management to clear objects after x days.
- Logs streamed to CloudWatch.
- Runner agents registered automatically.

The runner supports 3 main scenarios:

1. GitLab CI docker-machine runner - one runner agent

   In this scenario the runner agent is running on a single EC2 node and runners are created by [docker machine](https://docs.gitlab.com/runner/configuration/autoscale.html)
   using spot instances. Runners will scale automatically based on the configuration. The module creates a S3 cache by default,
   which is shared across runners (spot instances).

   ![runners-default](https://github.com/cattle-ops/terraform-aws-gitlab-runner/raw/main/assets/images/runner-default.png)

2. GitLab CI docker-machine runner - multiple runner agents

   In this scenario the multiple runner agents can be created with different configuration by instantiating the module multiple times.
   Runners will scale automatically based on the configuration. The S3 cache can be shared across runners by managing the cache
   outside the module.

   ![runners-cache](https://github.com/cattle-ops/terraform-aws-gitlab-runner/raw/main/assets/images/runner-cache.png)

3. GitLab Ci docker runner

   In this scenario _not_ docker machine is used but docker to schedule the builds. Builds will run on the same EC2 instance as the
   agent. No auto-scaling is supported.

   ![runners-docker](https://github.com/cattle-ops/terraform-aws-gitlab-runner/raw/main/assets/images/runner-docker.png)

For detailed concepts and usage please refer to [usage](docs/usage.md).

## Contributors ✨

PRs are welcome! Please see the [contributing guide](CONTRIBUTING.md) for more details.

Thanks to all the people who already contributed!

<!-- this is the only option to integrate the contributors list in the README.md -->
<!-- markdownlint-disable MD033 -->
<a href="https://github.com/cattle-ops/terraform-aws-gitlab-runner/graphs/contributors">
  <!-- markdownlint-disable MD033 -->
  <img src="https://contrib.rocks/image?repo=cattle-ops/terraform-aws-gitlab-runner" alt="contributors"/>
</a>

Made with [contributors-img](https://contrib.rocks).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Module Documentation

<!-- markdownlint-disable -->
<!-- cSpell:disable -->
<!-- markdown-link-check-disable -->
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
<!-- markdownlint-enable -->
<!-- cSpell:enable -->
<!-- markdown-link-check-enable -->
