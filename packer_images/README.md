To create an Amazon Machine Image (AMI) with Docker installed, you can use HashiCorp Packer. Packer is a tool for creating machine images for multiple platforms from a single source configuration.

Here you can find a step-by-step guide for different use cases.

# Prerequisites
Make sure Packer is installed on your local machine. You can download it from the Packer website.

Ensure the AWS CLI is installed and configured with appropriate credentials to create and manage resources in your AWS account.

# Amazon Linux 2023 AMI 

Use the provided template `amz-linux-docker.json` for building an amazon linux 2023 AMI and run Packer by executing the following command in your terminal:

```
packer build -var 'vpc_id=your_vpc_id' -var 'subnet_id=your_subnet_id' -var 'docker_registry_mirror=docker_registry_url' amz-linux-docker.json
```

The docker_registry_mirror argument is optional.

# Ubuntu AMI

Use the provided template `ubuntu-docker.json` for building an ubuntu AMI and run Packer by executing the following command in your terminal:

```
packer build -var 'vpc_id=your_vpc_id' -var 'subnet_id=your_subnet_id' -var 'docker_registry_mirror=docker-registry-url' ubuntu-docker.json 
```

The docker_registry_mirror argument is optional.

# Windows Server 2022 AMI

Use the provided template `windows-server-2022.hcl` for building a Windows Server 2022 AMI that can be used to set up a runner infrastructure that
uses Windows runners to run your jobs.

You can run Packed by executing the following command in your terminal:

```
packer build -var 'runner_version=your_runner_version' windows-server-2022.hcl
```

The `runner_version` argument is optional