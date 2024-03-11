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

## Accessing the cloned repository fails in Docker in Docker

If you follow the Docker in Docker (DinD) approach, you might face issues with accessing the cloned repository. The pipeline is
able to access all files and runs fine. But as soon as you start a new Docker container from within the pipeline, you notice
that the cloned repository is not available. You have to make it available as a volume using the path of your Docker host.

```yaml
# your pipeline
test:
  stage: test
  image: some/docker/image/here:stable
  script:
    - |
      # /builds is the host path the repository is mounted into the container executing the pipeline script
      DOCKER_CONTAINER_ID_SELF=$(cat /proc/self/cgroup | grep docker | head -n 1 | cut -d'/' -f3)
      DOCKER_HOST_BUILDS_DIRECTORY=$(docker inspect --format \
        '{{ range .Mounts }}{{ if eq .Destination "/builds" }}{{ .Source }}{{ end }}{{ end }}' \
        "${DOCKER_CONTAINER_ID_SELF}")
      
      # ${DOCKER_HOST_BUILDS_DIRECTORY}/${CI_PROJECT_PATH} now points to the root of you cloned repository and can be used
      # as a volume in Docker
      
      # starts some other containers
      docker-compose -f docker-compose.yml up -d

      # or mount all volumes from the runner container to the new container as well
      docker run --rm --volumes-from $(docker ps | grep runner | awk '{print $1}') ubuntu echo success
```

```yaml
# docker-compose.yml
postgres:
  image: postgres:14.1-alpine3.14
  volumes:
    - ${DOCKER_HOST_BUILDS_DIRECTORY}/${CI_PROJECT_PATH}/init_db.sql:/docker-entrypoint-initdb.d/init_db.sql
```
