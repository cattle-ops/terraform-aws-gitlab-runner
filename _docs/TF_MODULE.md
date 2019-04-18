## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| allow\_iam\_service\_linked\_role\_creation | Boolean used to control attaching the policy to a runner instance to create service linked roles. | string | `"true"` | no |
| ami\_filter | List of maps used to create the AMI filter for the Gitlab runner agent AMI. Currently Amazon Linux 2 `amzn2-ami-hvm-2.0.????????-x86_64-ebs` looks to *not* be working for this configuration. | list | `<list>` | no |
| ami\_owners | The list of owners used to select the AMI of Gitlab runner agent instances. | list | `<list>` | no |
| aws\_region | AWS region. | string | n/a | yes |
| aws\_zone | AWS availability zone (typically 'a', 'b', or 'c'). | string | `"a"` | no |
| cache\_bucket\_prefix | Prefix for s3 cache bucket name. | string | `""` | no |
| cache\_expiration\_days | Number of days before cache objects expires. | string | `"1"` | no |
| cache\_shared | Enables cache sharing between runners, false by default. | string | `"false"` | no |
| create\_runners\_iam\_instance\_profile | Boolean to control the creation of the runners IAM instance profile | string | `"true"` | no |
| docker\_machine\_instance\_type | Instance type used for the instances hosting docker-machine. | string | `"m5.large"` | no |
| docker\_machine\_options | List of additional options for the docker machine config. Each element of this list must be a key=value pair. E.g. '["amazonec2-zone=a"]' | list | `<list>` | no |
| docker\_machine\_spot\_price\_bid | Spot price bid. | string | `"0.04"` | no |
| docker\_machine\_user | Username of the user used to create the spot instances that host docker-machine. | string | `"docker-machine"` | no |
| docker\_machine\_version | Version of docker-machine. | string | `"0.16.1"` | no |
| enable\_cloudwatch\_logging | Boolean used to enable or disable the CloudWatch logging. | string | `"true"` | no |
| enable\_gitlab\_runner\_ssh\_access | Enables SSH Access to the gitlab runner instance. | string | `"false"` | no |
| enable\_manage\_gitlab\_token | Boolean to enable the management of the GitLab token in SSM. If `true` the Gitlab token will be managed via terraform state. If `false` the token will still be stored in SSM however, it will not be managed via terraform. | string | `"true"` | no |
| environment | A name that identifies the environment, used as prefix and for tagging. | string | n/a | yes |
| gitlab\_runner\_registration\_config | Configuration used to register the runner. See the README for an example, or reference the examples in the examples directory of this repo. | map | `<map>` | no |
| gitlab\_runner\_ssh\_cidr\_blocks | List of CIDR blocks to allow SSH Access from to the gitlab runner instance. | list | `<list>` | no |
| gitlab\_runner\_version | Version of the GitLab runner. | string | `"11.9.2"` | no |
| instance\_role\_json | Docker machine runner instance override policy, expected to be in JSON format. | string | `""` | no |
| instance\_role\_runner\_json | Instance role json for the docker machine runners to override the default. | string | `""` | no |
| instance\_type | Instance type used for the GitLab runner. | string | `"t3.micro"` | no |
| runner\_instance\_spot\_price | By setting a spot price bid price the runner agent will be created via a spot request. Be aware that spot instances can be stopped by AWS. | string | `""` | no |
| runners\_concurrent | Concurrent value for the runners, will be used in the runner config.toml. | string | `"10"` | no |
| runners\_environment\_vars | Environment variables during build execution, e.g. KEY=Value, see runner-public example. Will be used in the runner config.toml | list | `<list>` | no |
| runners\_executor | The executor to use. Currently supports `docker+machine` or `docker`. | string | `"docker+machine"` | no |
| runners\_gitlab\_url | URL of the GitLab instance to connect to. | string | n/a | yes |
| runners\_iam\_instance\_profile\_name | IAM instance profile name of the runners, will be used in the runner config.toml | string | `""` | no |
| runners\_idle\_count | Idle count of the runners, will be used in the runner config.toml. | string | `"0"` | no |
| runners\_idle\_time | Idle time of the runners, will be used in the runner config.toml. | string | `"600"` | no |
| runners\_image | Image to run builds, will be used in the runner config.toml | string | `"docker:18.03.1-ce"` | no |
| runners\_limit | Limit for the runners, will be used in the runner config.toml. | string | `"0"` | no |
| runners\_monitoring | Enable detailed cloudwatch monitoring for spot instances. | string | `"false"` | no |
| runners\_name | Name of the runner, will be used in the runner config.toml. | string | n/a | yes |
| runners\_off\_peak\_idle\_count | Off peak idle count of the runners, will be used in the runner config.toml. | string | `"0"` | no |
| runners\_off\_peak\_idle\_time | Off peak idle time of the runners, will be used in the runner config.toml. | string | `"0"` | no |
| runners\_off\_peak\_periods | Off peak periods of the runners, will be used in the runner config.toml. | string | `""` | no |
| runners\_off\_peak\_timezone | Off peak idle time zone of the runners, will be used in the runner config.toml. | string | `""` | no |
| runners\_output\_limit | Sets the maximum build log size in kilobytes, by default set to 4096 (4MB) | string | `"4096"` | no |
| runners\_post\_build\_script | Commands to be executed on the Runner just after executing the build, but before executing after_script. | string | `""` | no |
| runners\_pre\_build\_script | Script to execute in the pipeline just before the build, will be used in the runner config.toml | string | `""` | no |
| runners\_pre\_clone\_script | Commands to be executed on the Runner before cloning the Git repository. this can be used to adjust the Git client configuration first, for example. | string | `""` | no |
| runners\_privileged | Runners will run in privileged mode, will be used in the runner config.toml | string | `"true"` | no |
| runners\_request\_concurrency | Limit number of concurrent requests for new jobs from GitLab (default 1) | string | `"1"` | no |
| runners\_root\_size | Runner instance root size in GB. | string | `"16"` | no |
| runners\_shm\_size | shm_size for the runners.  will be used in the runner config.toml | string | `"0"` | no |
| runners\_token | Token for the runner, will be used in the runner config.toml. | string | `"__REPLACED_BY_USER_DATA__"` | no |
| runners\_use\_private\_address | Restrict runners to the use of a private IP address | string | `"true"` | no |
| secure\_parameter\_store\_runner\_token\_key | The key name used store the Gitlab runner token in Secure Parameter Store | string | `"runner-token"` | no |
| ssh\_public\_key | Public SSH key used for the GitLab runner EC2 instance. | string | n/a | yes |
| subnet\_id\_runners | List of subnets used for hosting the gitlab-runners. | string | n/a | yes |
| subnet\_ids\_gitlab\_runner | Subnet used for hosting the GitLab runner. | list | n/a | yes |
| tags | Map of tags that will be added to created resources. By default resources will be tagged with name and environment. | map | `<map>` | no |
| userdata\_post\_install | User-data script snippet to insert after GitLab runner install | string | `""` | no |
| userdata\_pre\_install | User-data script snippet to insert before GitLab runner install | string | `""` | no |
| vpc\_id | The target VPC for the docker-machine and runner instances. | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| runner\_agent\_role | ARN of the rule used for the ec2 instance for the GitLab runner agent. |
| runner\_as\_group\_name | Name of the autoscaling group for the gitlab-runner instance |
| runner\_cache\_bucket\_arn | ARN of the S3 for the build cache. |
| runner\_role | ARN of the rule used for the docker machine runners. |

