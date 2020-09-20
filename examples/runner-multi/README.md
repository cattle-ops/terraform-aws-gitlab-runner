# Example - Multi-runner

This is example for registering multiple runners under the same token. Runners differ with instance type and subnets and are selected randomly. You can treat it as a poor man's spot instance pool.

You can also preregister runners and pass runner token to each element of `runners` array separately. This way you can run one spot instance pool and one more reliable, non-spot pool using the same runner agent instance.

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

## Outputs

No output.
