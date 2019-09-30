# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).


## Unrelease

## 4.6.0 - 2019-09-30
- Add access_level option to registration call in runner template #134 @willychenchen 
- Bump gitlab-runner default version to 12.3.0 #135 @loustler 

## 4.5.0 - 2019-09-09
- Set docker machine version by default to 0.16.2 #131 @npalm
- Add SSM session manager support #121 #126 @npalm
- Move to github actions #130 @npalm
- Enable s3 encryption #129 @hendrixroa
- Bump gitlab-runner to 12.2.0 #128 @mpsq

## 4.4.0 - 2019-08-21

- Added
  - Allow for configurable root block size #123 @bsuv
  - Enable ASG scheduling #119 @bsuv


## 4.3.0 - 2019-08-19

- Added
  - Add MaxBuilds variable to gitlab runner config #122 @gertjanmaas

## 4.2.0 - 2019-08-18

- Added
  - Option to disable account id is used in bucket name #113 @Glen-Moonpig 
  - Cancel sport instances during destroy for example default and public.
- Changed:
  - Fixed typos #118 @mpsq 


## 4.1.0 - 2019-08-05

- Changed:
  - Runner tags namespaced with ":" are split wrong in userdata. #111 @ony-harverson-moonpig


## 4.0.0 - 2019-07-29

### Terraform 0.12

Module is available as Terraform 0.12 module, pin to version 4.x. Please submit pull-requests to the `develop` branch.

Migration from 0.11 to 0.12 is tested for the `runner-default` example. To migrate the runner, execute the following steps.

- Update to Terraform 0.12
- Migrate your Terraform code via Terraform `terraform 0.12upgrade`.
- Update the module from 3.10.0 to 4.0.0, next run `terraform init`
- Run `terraform apply`. This should trigger only a re-creation of the the auto launch configuration and a minor change in the auto-scaling group.

### Terraform 0.11

Module is available as Terraform 0.11 module, pin module to version 3.x. Please submit pull-requests to the `terraform011` branch.

## 3.10.0 - 2019-07-29
- Chnaged
  - THe user data script for the EC2 runner agent instance is not logging anymore on trace level. To enable bash xtrace set `enable_runner_user_data_trace_log` to `true`. #49
  - Generate links for Readme during release, #63

## 3.9.0 - 2019-07-26
- Changed
  - Update default runner version to 12.1.0 (#106)
- Added
  - Add runners_volumes variable (#105) @kevinrambaud

## 3.8.0 - 2019-07-22
- Added
  - Variable `docker_machine_ssh_cidr_blocks` to set CIDR for ingress on docker machine SSH rules. @kevinrambaud #101
  -  Variable `docker_machine_role_json` allowing role policy customization #kevinrambaud #100

## 3.7.0 - 2019-07-17
- Changed
  - Creation of multiple instances of the runner is now supported. Cache is therefore moved to an internal module. Pleas see the example `runner-public` for a concrete sample. The change should have no effect if you apply the state migration script `migragations/migration-state-3.7.x.sh`.
  - Examples are more generic by removing the time zone and AZ zone to variables. @@theBenForce

## 3.6.0 - 2019-07-04
- Changed
  - Add option to specify pull policy for docker images by the runner. @roock
  - Docker machine AMI image will be by default latest ubuntu 16.06, can be overwritten via variables @roock
  - Improved CI docs generation script @roock

## 3.5.0 - 2019-06-19
- Changed
  - Documentation #85: Misleading Variable-Description @solutionDrive-Alt
  - Bugfix #70: docker-machine fails starting runners when `amazonec2-request-spot-instance=false` @philippefuentes
  - Bugfix #72: Detect and retry when docker machine installation fails @eliasdorneles
  - Changed: Default version of GitLab runner set to 11.11.2

## 3.7.0 - 2019-07-17
- Changed
  - Creation of multiple instances of the runner is now supported. Cache is therefore moved to an internal module. Pleas see the example `runner-public` for a concrete sample. The change should have no effect if you apply the state migration script `migragations/migration-state-3.7.x.sh`.
  - Examples are more generic by removing the time zone and AZ zone to variables. @@theBenForce

## 3.6.0 - 2019-07-04
- Changed
  - Add option to specify pull policy for docker images by the runner. @roock
  - Docker machine AMI image will be by default latest ubuntu 16.06, can be overwritten via variables @roock
  - Improved CI docs generation script @roock

## 3.5.0 - 2019-06-19
- Changed
  - Documentation #85: Misleading Variable-Description @solutionDrive-Alt
  - Bugfix #70: docker-machine fails starting runners when `amazonec2-request-spot-instance=false` @philippefuentes
  - Bugfix #72: Detect and retry when docker machine installation fails @eliasdorneles
  - Changed: Default version of GitLab runner set to 11.11.2

## [3.4.0] - 2019-06-06
- Changed:
  - Update default runner type, GitLab runner version, and versions in examples.
  - Buffix #75 runner is not reachable when runners_use_private_address = false
  - Buffix - Missing typ - @Orkin
  - Bugfix #72 - Detect and retry when docker machine download fails eliasdorneles
  - Bugfix #68 - add count to prevent resource creation failing  @philippefuentes
  - Bugfix #70 - update policy to allow runners to start when not using spot instances  @philippefuentes

## [3.3.0] - 2019-05-20
- Changed: Default version of GitLab runner set to 11.10.1
- Added: Option to enable / disable SSH login
- Added: Option to use spot instances for runner instance
- Changed: Default instance type is now m5.large
- Added: Custom names for instance and security groups

## [3.2.0] - 2019-03-09
- Added: Option to set shm_size for the runners, default remains 0.

## [3.1.0] - 2019-03-09
- Added: Option to set environment variables for the runners, see the variable `runners_environment_vars`. An example added to the `public-runner` example.

## [3.0.0] - 2019-03-29
- Changed: The runner will register itself based on the registration token. No need to preregister the runner before running terraform. See the [README](README.md) for configuration and migration. #33

## [2.3.0] - 2019-03-27
- Bugfix: Added a profile for the docker machine runners. #41
- Changed: Changed the name of runner instance, added `docker-machine` to the name.

## [2.2.1] - 2019-03-19
- Bugfix: Add tags to spot instances #39
- Changed: Updated terraform providers in examples and default terraform version

## [2.2.0] - 2019-03-08
- Changed: Upgrade default runner agent to 11.8.0 and docker machine to 0.16.1
- Bugfix: Correct example for docker_machine_options #36 (@declension)
- Added: AWS Zone variable #35 (@declension)

## [2.1.0] - 2019-02-28
- Bugfix: Shared cache is not working #33
- Bugfix: Missing documentation makes setup fail #31
- Added: Docker executor to run a single node runner, thanks to @msvechla

## [2.0.0] - 2019-01-13
- Changed: Replaced cache user by a instance profile to access the cache from the build
- Changed: Update gitlab toml cache section, removed deprecated usages of s3
- Changed: The variable `amazon_optimized_amis` is removed an replaced by a filter to select the AMI. To use the default of the latest AMI set the filter `ami_filter` to `amzn-ami-hvm-2018.03.0.20180622-x86_64-ebs`.
- Added: Option to set docker machine options via `docker_machine_optionns`.
- Added: Several output variables.


## [1.8.0] - 2018-12-30
- Changed: Update default docker-machine version to 0.16.0
- Changed: Update default gitlab runner to 11.6.0
- Added: Configuration parameters for post_build_script, pre_clone_script, request_concurrency and output_limit. #22
- Added: Configurable docker image for runner #27
- Added: Add pre/post install user-data snippets for runners #26

## [1.7.0] - 2018-11-21
- Added option to configure instance-profile for runner pre build script. Thanks to @msvechla

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

[Unreleased]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/4.6.0...HEAD
[4.6.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/4.5.0...4.6.0
[4.5.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/4.4.0...4.5.0
[4.4.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/4.3.0...4.4.0
[4.3.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/4.2.0...4.3.0
[4.2.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/4.1.0...4.2.0
[4.1.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/4.0.0...4.1.0
[4.0.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/3.10.0...4.0.0
[3.10.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/3.9.0...3.10.0
[3.9.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/3.8.0...3.9.0
[3.8.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/3.7.0...3.8.0
[3.7.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/3.6.0...3.7.0
[3.6.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/3.5.0...3.6.0
[3.5.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/3.4.0...3.5.0
[3.4.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/3.3.0...3.4.0
[3.3.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/3.2.0...3.3.0
[3.2.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/3.1.0...3.2.0
[3.1.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/3.0.0...3.1.0
[3.0.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/2.3.0...3.0.0
[2.3.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/2.2.1...2.3.0
[2.2.1]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/2.2.0...2.2.1
[2.2.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/2.1.0...2.2.0
[2.1.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/1.8.0...2.0.0
[1.8.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/1.7.0...1.8.0
[1.7.0]: https://github.com/npalm/terraform-aws-gitlab-runner/compare/1.6.0...1.7.0
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
