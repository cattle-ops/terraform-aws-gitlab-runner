# Example - Custom Terraform Spot Fleet

This is hopefully the answer to reliable spot instances with Gitlab Runner and AWS.
We utilize a custom Terraform Docker Machine Driver and configuration in `worker-config` directory to dynamically provision Gitlab runners with Spot Fleet requests. 

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
