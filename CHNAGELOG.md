# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
## [1.6.0] - 2018-10-06
- Updated the default GitLab Runner to 11.3.1

## [1.5.0] - 2018-08-10
- Updated default AMI map to Amazon Linux AMI 2018.03 was released on 2018-06-28

## [1.4.0] - 2018-08-09
### Added
- Added an option to allow gitlab runner instance to create service linked roles, by default enabled.
- Added example for public subnet

## [1.3.0] - 2018-08-08
- Add option to run runners in public subnet

## [1.2.1] - 2018-08-02
### Changed
- Add work around to README for missing service linked roles, see #15

## [1.2.0] - 2018-07-30
### Added
- Add a map for for a more flexible mechanism to tag.

### Changed
- Set default gitlab runner to 11.1.0
- Replaced the dedicated docker machine user by an instance profile
- Limit the resources access for docker machine.
- Updated default docker build image to 18.03.1-ce

### Fixes
- Add fix for non correct ec2 instances starting, add retry to yum update

## [1.1.0] - 2018-07-14
### Added
- Add variable to enable cloudwatch monitoring for spot instances, by default disabled.
- Add off peak runner settings.
- Add file system root size for runners.

### Changed
- Refactored example, key generation is part of terraform.

## [1.0.3] - 2018-07-14
### Changed
- Add parameter for docker machine version
- Upgrade default gitlab runner version to 11.0.0
- Upgrade default docker-machine version to 0.15.0

## [1.0.2] - 2018-06-22
### Changed
- Add link to blog for a detailed setup description

## [1.0.1] - 2018-06-21
### Changed
- Moved example so it is shown in the registry

## [1.0.0] - 2018-06-19
### Changed
- Default Gitlab runner version set to 10.8.0
- Update default AMI's to The latest Amazon Linux AMI 2017.09.1 - released on 2018-01-17.
- Minor updates in the example

[Unreleased]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/1.6.0...HEAD
[1.6.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/1.5.0...1.6.0
[1.5.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/1.4.0...1.5.0
[1.4.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/1.3.0...1.4.0
[1.3.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/1.2.1...1.3.0
[1.2.1]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/1.0.3...1.1.0
[1.0.3]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/0.2.0...1.0.0
