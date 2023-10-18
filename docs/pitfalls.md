# Common Pitfalls

## Setting the name of the instances via name tag

It doesn't work, but the modules supports the `runner_instance.name` and `runner_worker_docker_machine_instance` variable. Set them
to any value to adjust the name of the EC2 instance(s).

```hcl
# working
runner_instance = {
  name  = "my-gitlab-runner-name"
}

# not working
runner_instance = {
  additional_tags = {
    Name = "my-gitlab-runner-name"
  }
}
```

## Apply with shared cache bucket fails

In case you manage the S3 cache bucket yourself it might be necessary to apply the cache before applying the runner module. A
typical error message looks like:

```text
Error: Invalid count argument
on .terraform/modules/gitlab_runner/main.tf line 400, in resource "aws_iam_role_policy_attachment" "docker_machine_cache_instance":
  count = var.cache_bucket["create"] || length(lookup(var.cache_bucket, "policy", "")) > 0 ? 1 : 0
The "count" value depends on resource attributes that cannot be determined until apply, so Terraform cannot predict how many
instances will be created. To work around this, use the -target argument to first apply only the resources that the count
depends on.
```

The workaround is to use a `terraform apply -target=module.cache` followed by a `terraform apply` to apply everything else. This is
a one time effort needed at the very beginning.
