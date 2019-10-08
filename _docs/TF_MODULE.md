## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| allow\_iam\_service\_linked\_role\_creation | Boolean used to control attaching the policy to a runner instance to create service linked roles. | bool | `"true"` | no |
| ami\_filter | List of maps used to create the AMI filter for the Gitlab runner agent AMI. Currently Amazon Linux 2 `amzn2-ami-hvm-2.0.????????-x86_64-ebs` looks to *not* be working for this configuration. | map(list(string)) | `<map>` | no |
| ami\_owners | The list of owners used to select the AMI of Gitlab runner agent instances. | list(string) | `<list>` | no |
| aws\_region | AWS region. | string | n/a | yes |
| aws\_zone | AWS availability zone (typically 'a', 'b', or 'c'). | string | `"a"` | no |
| cache\_bucket | Configuration to control the creation of the cache bucket. By default the bucket will be created and used as shared cache. To use the same cache cross multiple runners disable the cration of the cache and provice a policy and bucket name. See the public runner example for more details. | map | `<map>` | no |
| cache\_bucket\_name\_include\_account\_id | Boolean to add current account ID to cache bucket name. | bool | `"true"` | no |
| cache\_bucket\_prefix | Prefix for s3 cache bucket name. | string | `""` | no |
| cache\_bucket\_versioning | Boolean used to enable versioning on the cache bucket, false by default. | bool | `"false"` | no |
| cache\_expiration\_days | Number of days before cache objects expires. | number | `"1"` | no |
| cache\_shared | Enables cache sharing between runners, false by default. | bool | `"false"` | no |
| docker\_machine\_docker\_cidr\_blocks | List of CIDR blocks to allow Docker Access to the docker machine runner instance. | list(string) | `<list>` | no |
| docker\_machine\_instance\_type | Instance type used for the instances hosting docker-machine. | string | `"m5a.large"` | no |
| docker\_machine\_options | List of additional options for the docker machine config. Each element of this list must be a key=value pair. E.g. '["amazonec2-zone=a"]' | list(string) | `<list>` | no |
| docker\_machine\_role\_json | Docker machine runner instance override policy, expected to be in JSON format. | string | `""` | no |
| docker\_machine\_spot\_price\_bid | Spot price bid. | string | `"0.06"` | no |
| docker\_machine\_ssh\_cidr\_blocks | List of CIDR blocks to allow SSH Access to the docker machine runner instance. | list(string) | `<list>` | no |
| docker\_machine\_version | Version of docker-machine. | string | `"0.16.2"` | no |
| enable\_cloudwatch\_logging | Boolean used to enable or disable the CloudWatch logging. | bool | `"true"` | no |
| enable\_gitlab\_runner\_ssh\_access | Enables SSH Access to the gitlab runner instance. | bool | `"false"` | no |
| enable\_manage\_gitlab\_token | Boolean to enable the management of the GitLab token in SSM. If `true` the token will be stored in SSM, which means the SSM property is a terraform managed resource. If `false` the Gitlab token will be stored in the SSM by the user-data script during creation of the the instance. However the SSM parameter is not managed by terraform and will remain in SSM after a `terraform destroy`. | bool | `"true"` | no |
| enable\_runner\_ssm\_access | Add IAM policies to the runner agent instance to connect via the Session Manager. | bool | `"false"` | no |
| enable\_runner\_user\_data\_trace\_log | Enable bash xtrace for the user data script that creates the EC2 instance for the runner agent. Be aware this could log sensitive data such as you GitLab runner token. | bool | `"false"` | no |
| enable\_schedule | Flag used to enable/disable auto scaling group schedule for the runner instance. | bool | `"false"` | no |
| environment | A name that identifies the environment, used as prefix and for tagging. | string | n/a | yes |
| gitlab\_runner\_registration\_config | Configuration used to register the runner. See the README for an example, or reference the examples in the examples directory of this repo. | map(string) | `<map>` | no |
| gitlab\_runner\_ssh\_cidr\_blocks | List of CIDR blocks to allow SSH Access to the gitlab runner instance. | list(string) | `<list>` | no |
| gitlab\_runner\_version | Version of the GitLab runner. | string | `"12.3.0"` | no |
| instance\_role\_json | Default runner instance override policy, expected to be in JSON format. | string | `""` | no |
| instance\_type | Instance type used for the GitLab runner. | string | `"t3.micro"` | no |
| overrides | This maps provides the possibility to override some defaults. The following attributes are supported: `name_sg` overwrite the `Name` tag for all security groups created by this module. `name_runner_agent_instance` override the `Name` tag for the ec2 instance defined in the auto launch configuration. `name_docker_machine_runners` ovverrid the `Name` tag spot instances created by the runner agent. | map(string) | `<map>` | no |
| runner\_ami\_filter | List of maps used to create the AMI filter for the Gitlab runner docker-machine AMI. | map(list(string)) | `<map>` | no |
| runner\_ami\_owners | The list of owners used to select the AMI of Gitlab runner docker-machine instances. | list(string) | `<list>` | no |
| runner\_instance\_spot\_price | By setting a spot price bid price the runner agent will be created via a spot request. Be aware that spot instances can be stopped by AWS. | string | `""` | no |
| runner\_root\_block\_device | The EC2 instance root block device configuration. Takes the following keys: `delete_on_termination`, `volume_type`, `volume_size`, `iops` | map(string) | `<map>` | no |
| runners\_additional\_volumes | Additional volumes that will be used in the runner config.toml, e.g Docker socket | list | `<list>` | no |
| runners\_concurrent | Concurrent value for the runners, will be used in the runner config.toml. | number | `"10"` | no |
| runners\_environment\_vars | Environment variables during build execution, e.g. KEY=Value, see runner-public example. Will be used in the runner config.toml | list(string) | `<list>` | no |
| runners\_executor | The executor to use. Currently supports `docker+machine` or `docker`. | string | `"docker+machine"` | no |
| runners\_gitlab\_url | URL of the GitLab instance to connect to. | string | n/a | yes |
| runners\_iam\_instance\_profile\_name | IAM instance profile name of the runners, will be used in the runner config.toml | string | `""` | no |
| runners\_idle\_count | Idle count of the runners, will be used in the runner config.toml. | number | `"0"` | no |
| runners\_idle\_time | Idle time of the runners, will be used in the runner config.toml. | number | `"600"` | no |
| runners\_image | Image to run builds, will be used in the runner config.toml | string | `"docker:18.03.1-ce"` | no |
| runners\_limit | Limit for the runners, will be used in the runner config.toml. | number | `"0"` | no |
| runners\_max\_builds | Max builds for each runner after which it will be removed, will be used in the runner config.toml. By default set to 0, no maxBuilds will be set in the configuration. | number | `"0"` | no |
| runners\_monitoring | Enable detailed cloudwatch monitoring for spot instances. | bool | `"false"` | no |
| runners\_name | Name of the runner, will be used in the runner config.toml. | string | n/a | yes |
| runners\_off\_peak\_idle\_count | Off peak idle count of the runners, will be used in the runner config.toml. | number | `"0"` | no |
| runners\_off\_peak\_idle\_time | Off peak idle time of the runners, will be used in the runner config.toml. | number | `"0"` | no |
| runners\_off\_peak\_periods | Off peak periods of the runners, will be used in the runner config.toml. | string | `""` | no |
| runners\_off\_peak\_timezone | Off peak idle time zone of the runners, will be used in the runner config.toml. | string | `""` | no |
| runners\_output\_limit | Sets the maximum build log size in kilobytes, by default set to 4096 (4MB) | number | `"4096"` | no |
| runners\_post\_build\_script | Commands to be executed on the Runner just after executing the build, but before executing after_script. | string | `""` | no |
| runners\_pre\_build\_script | Script to execute in the pipeline just before the build, will be used in the runner config.toml | string | `""` | no |
| runners\_pre\_clone\_script | Commands to be executed on the Runner before cloning the Git repository. this can be used to adjust the Git client configuration first, for example. | string | `""` | no |
| runners\_privileged | Runners will run in privileged mode, will be used in the runner config.toml | bool | `"true"` | no |
| runners\_pull\_policy | pull_policy for the runners, will be used in the runner config.toml | string | `"always"` | no |
| runners\_request\_concurrency | Limit number of concurrent requests for new jobs from GitLab (default 1) | number | `"1"` | no |
| runners\_root\_size | Runner instance root size in GB. | number | `"16"` | no |
| runners\_services\_volumes\_tmpfs | Mount temporary file systems to service containers. Must consist of pairs of strings e.g. "/var/lib/mysql" = "rw,noexec", see example | list | `<list>` | no |
| runners\_shm\_size | shm_size for the runners, will be used in the runner config.toml | number | `"0"` | no |
| runners\_token | Token for the runner, will be used in the runner config.toml. | string | `"__REPLACED_BY_USER_DATA__"` | no |
| runners\_use\_private\_address | Restrict runners to the use of a private IP address | bool | `"true"` | no |
| runners\_volumes\_tmpfs | Mount temporary file systems to the main containers. Must consist of pairs of strings e.g. "/var/lib/mysql" = "rw,noexec", see example | list | `<list>` | no |
| schedule\_config | Map containing the configuration of the ASG scale-in and scale-up for the runner instance. Will only be used if enable_schedule is set to true. | map | `<map>` | no |
| secure\_parameter\_store\_runner\_token\_key | The key name used store the Gitlab runner token in Secure Parameter Store | string | `"runner-token"` | no |
| ssh\_key\_pair | Set this to use existing AWS key pair | string | `""` | no |
| ssh\_public\_key | Public SSH key used for the GitLab runner EC2 instance. | string | `""` | no |
| subnet\_id\_runners | List of subnets used for hosting the gitlab-runners. | string | n/a | yes |
| subnet\_ids\_gitlab\_runner | Subnet used for hosting the GitLab runner. | list(string) | n/a | yes |
| tags | Map of tags that will be added to created resources. By default resources will be tagged with name and environment. | map(string) | `<map>` | no |
| userdata\_post\_install | User-data script snippet to insert after GitLab runner install | string | `""` | no |
| userdata\_pre\_install | User-data script snippet to insert before GitLab runner install | string | `""` | no |
| vpc\_id | The target VPC for the docker-machine and runner instances. | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| runner\_agent\_role\_arn | ARN of the role used for the ec2 instance for the GitLab runner agent. |
| runner\_agent\_role\_name | Name of the role used for the ec2 instance for the GitLab runner agent. |
| runner\_agent\_sg\_id | ID of the security group attached to the GitLab runner agent. |
| runner\_as\_group\_name | Name of the autoscaling group for the gitlab-runner instance |
| runner\_cache\_bucket\_arn | ARN of the S3 for the build cache. |
| runner\_cache\_bucket\_name | Name of the S3 for the build cache. |
| runner\_role\_arn | ARN of the role used for the docker machine runners. |
| runner\_role\_name | Name of the role used for the docker machine runners. |
| runner\_sg\_id | ID of the security group attached to the docker machine runners. |

