# Example - Multi-runner

This example makes use of [Terraform driver for Docker Machine](https://github.com/krzysztof-miemiec/docker-machine-driver-terraform). As a result, we can create real spot requests for each Gitlab runner we want to create and pay less for more. This example registers multiple runners under the same token.

You can also preregister runners and pass runner token to each element of `runners` array separately. This way you can run one spot instance pool and one more reliable, non-spot pool using the same runner agent instance.

## Custom AMI

For performance reasons you may want to use a custom AMI. The one in this example creates Ubuntu machine, adds Docker and AWS CLI, so the boot time is faster and causes less network traffic. 

## Terraform deployed through Terraform running on each machine creation

Our custom Docker Machine driver can execute any Terraform code, which means, that you can write a fully custom runner "stack". It can involve spot instance (as in this case) or do even more (create any resource is supported via Terraform). The driver uses IAM permissions given in `./main.tf` - we aim to keep it minimal.

Terraform script provided in this example involves a lot of hacks, which would not work in "real" Terraform setup.
- no remote backend, everything is local
- if "manager" instance fails, you'll have to clean up runners manually
- we periodically clean up machines that got stuck for some random reason to avoid hitting any AWS/Docker/Gitlab runner limits (see last few lines of `docker-machine-terraform.sh`)
- a custom script in `worker-config/main.tf` polls for EC2 status - when it's ready, it obtains EC2 instance id and stores it in `instance_id.txt`. When this is done, we return all outputs via Terraform

## Providers

| Name | Version |
|------|---------|
| aws | 2.52 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| aws\_region | AWS region. | `string` | `"eu-west-1"` | no |
| environment | A name that identifies the environment, will used as prefix and for tagging. | `string` | `"ci-runners"` | no |
| gitlab\_url | URL of the gitlab instance to connect to. | `string` | n/a | yes |
| runner\_name | Name of the runner, will be used in the runner config.toml | `string` | n/a | yes |
| runner\_token | Registration token for all runners | `string` | n/a | yes |
| timezone | Name of the timezone that the runner will be used in. | `string` | `"Europe/Amsterdam"` | no |
| image_id | Run build.sh script to build a stable AMI for your instances with Packer. | `string` | n/a | yes |

## Outputs

No output.
