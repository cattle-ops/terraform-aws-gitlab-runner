# Example - Spot Runner - Private subnet

In this scenario the runner agent is running on a single EC2 node.

The example is intended to show how the runner can be configured for self-hosted Gitlab environments with certificates
signed by a custom CA.

> This currently only works with the `docker` executor. Support for the `docker+machine` executor is not yet
> implemented. Contributions are welcome.

## Prerequisites

The terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please
check `.terraform-version` for the tested version.

Before configuring certificates, it is important to review the [Gitlab documentation](https://docs.gitlab.com/runner/configuration/tls-self-signed.html).

In particular, note the following docker images are involved:

- The **Runner helper image**, which is used to handle Git, artifacts, and cache operations. In this scenario, the
  user only needs to make a certificate file available at a specific location (for example 
  /etc/gitlab-runner/certs/ca.crt), and the Docker container will automatically install it for the user.
- The **user image**, which is used to run the user script. In this scenario, the user must take ownership regarding
  how to install a certificate, since this is highly dependent on the image itself, and the Runner has no way of
  knowing how to install a certificate in each possible scenario.

### Certificates for the runner-helper image

The Gitlab **runner-helper image** needs to communicate with your Gitlab instance.

Create a PEM-encoded `.crt` file containing the public certificate of your Gitlab server instance.

```hcl
module {
  # ...
  # Public cert of my companys gitlab instance
  runner_gitlab = {
    certificate = file("${path.module}/my_gitlab_instance_cert.crt")
  }  
  # ...
}
```

Add your CA and intermediary certs to a second PEM-encoded `.crt` file.
```hcl
module {
  # ...
  # Other public certs relating to my company.
  runner_gitlab = {
    ca_certificate = file("${path.module}/my_company_ca_cert_bundle.crt")
  }
  # ...
}
```

### Certificates for user images

For **user images**, you must:

1. Mount the certificates from the EC2 host into all user images.

    The runner module can be configured to do this step. Configure the module like so:
    
    ```terraform
    module "runner" {
      # ...
      
      # Mount EC2 host certs in docker so all user docker images can reference them.
      runner_worker_docker_options = {
        volumes = ["/etc/gitlab-runner/certs/:/etc/gitlab-runner/certs:ro"]
      }
      
      # ...
    }
    ```
      
2. Trust the certificates from within the user image.
  
    Each user image will need to execute commands to copy the certificates into the correct place and trust them.
    
    The below examples some ways to do this, assuming user images with the Ubuntu OS or similar.
    For Alpine OS user images, the specific commands may differ.
    
    **Option 1:** Build a custom user image and update your `Dockerfile`:
    ```docker
      FROM python:3 # Some base image
    
      RUN apt-get -y update
      RUN apt-get -y upgrade
    
      RUN apt-get install -y ca-certificates
      RUN cp /etc/gitlab-runner/certs/* /usr/local/share/ca-certificates/
      RUN update-ca-certificates
      ...
    ```
    
    **Option 2:** Add a section to each pipeline using `before_script`:
    
    This change would need to be added to every pipeline file which requires certificates.
    It could be customized depending on the OS of the pipeline user image.
    
    ```yaml
    default:
      before_script:
        # Install certificates into user image
        - apt-get install -y ca-certificates
        - cp /etc/gitlab-runner/certs/* /usr/local/share/ca-certificates/
        - update-ca-certificates
    ```
    
    **Option 3:** Add the script from Option 2 into `runners_pre_build_script` variable:
    
    This avoids maintaining the script in each pipeline file, but expects that all user images use the same OS.
    
    ```terraform
    module "runner" {
      # ...
    
      runner_worker_gitlab_pipeline = {
        pre_build_script = <<EOT
        '''
        apt-get install -y ca-certificates
        cp /etc/gitlab-runner/certs/* /usr/local/share/ca-certificates/
        update-ca-certificates
        '''
        EOT
      }
      # ...
    }
    ```
  
<!-- markdownlint-disable -->
<!-- cSpell:disable -->
<!-- markdown-link-check-disable -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.25.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | 2.4.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | 3.2.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.5.1 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 4.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.25.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_runner"></a> [runner](#module\_runner) | ../../ | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.1.2 |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | 5.1.2 |

## Resources

| Name | Type |
|------|------|
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/5.25.0/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region. | `string` | `"eu-west-1"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | A name that identifies the environment, will used as prefix and for tagging. | `string` | `"runners-docker"` | no |
| <a name="input_gitlab_url"></a> [gitlab\_url](#input\_gitlab\_url) | URL of the gitlab instance to connect to. | `string` | `"https://gitlab.com"` | no |
| <a name="input_registration_token"></a> [registration\_token](#input\_registration\_token) | Gitlab runner registration token | `string` | `"something"` | no |
| <a name="input_runner_name"></a> [runner\_name](#input\_runner\_name) | Name of the runner, will be used in the runner config.toml | `string` | `"docker"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
