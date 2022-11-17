# Example - Spot Runner - Private subnet

In this scenario the runner agent is running on a single EC2 node.

The example is intended to show how the runner can be configured for self-hosted Gitlab environments with certificates signed by a custom CA.

## Prerequisites

The terraform version is managed using [tfenv](https://github.com/Zordrak/tfenv). If you are not using `tfenv` please check `.terraform-version` for the tested version.

Before configuring certificates, it is important to review the [Gitlab documentation](https://docs.gitlab.com/runner/configuration/tls-self-signed.html).

In particular, note the following docker images are involved:

> - The **Runner helper image**, which is used to handle Git, artifacts, and cache operations. In this scenario, the user only needs to make a certificate file available at a specific location (for example, /etc/gitlab-runner/certs/ca.crt), and the Docker container will automatically install it for the user.

> - The **user image**, which is used to run the user script. In this scenario, the user must take ownership regarding how to install a certificate, since this is highly dependent on the image itself, and the Runner has no way of knowing how to install a certificate in each possible scenario.

### Certificates for the runner-helper image

The Gitlab **runner-helper image** needs to communicate with your Gitlab instance. 

Create a PEM-encoded `.crt` file containing the public certificate of your Gitlab server instance.

```hcl
module {
  ...
  # Public cert of my companys gitlab instance
  runners_gitlab_certificate = file("${path.module}/my_gitlab_instance_cert.crt")
  ...
}
```

Add your CA and intermediary certs to a second PEM-encoded `.crt` file.
```hcl
module {
  ...
  # Other public certs relating to my company.
  runners_ca_certificate = file("${path.module}/my_company_ca_cert_bundle.crt")
  ...
}
```

### Certificates for user images

For **user images**, you must:

1. Mount the certificates from the EC2 host into all user images.  

The runner module can be configured to do this step. Configure the module like so:
```hcl
module {
  ...
  # Mount EC2 host certs in docker so all user docker images can reference them.
  runners_additional_volumes = ["/etc/gitlab-runner/certs/:/etc/gitlab-runner/certs:ro"]
  ...
}
```

2. Trust the certificates from within the user image.

Each user image will need to execute commands to copy the certificates into the correct place and trust them.

The below examples show two possible ways to do this, for Ubuntu user images.

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

**Option 2:** Adding a section to each pipeline using `before_script`:
```yaml
default:
  before_script:
    - apt-get install -y ca-certificates
    - cp /etc/gitlab-runner/certs/* /usr/local/share/ca-certificates/
    - update-ca-certificates
```


<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->