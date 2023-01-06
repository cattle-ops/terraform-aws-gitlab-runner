# Infrastructure tests

The tests are still in an experimental phase. Feel free to create a PR with any improvement or suggestion.

## Setup

Test are written in [Go](https://golang.org/). Using [Terratest](https://github.com/gruntwork-io/terratest). Ensure you install and setup

- [Go](https://golang.org/)
- [dep](https://github.com/golang/dep)

The following enviroment variables are required to set or add in a file `.env`.

Sample `.env` file:
```
GITLAB_ACCESS_TOKEN="MY_ACCESS_TOKEN"
GITLAB_RUNNER_REGISTRATION_TOKEN="MY_RUNNER_TOKEN"
GITLAB_NAMESPACE="<YOUR_TEST_NAMESPACE>"
```

## Environment variables.


|                                  | description                                                               | required | default                          |
| -------------------------------- | ------------------------------------------------------------------------- | -------- | -------------------------------- |
| GITLAB_ACCESS_TOKEN              | GitLab access token used to access the GitLab API                         | yes      |                                  |
| GITLAB_NAMESPACE                 | GitLab namespaced used to fork (create) project for running the tests.    | yes      |                                  |
| GITLAB_RUNNER_REGISTRATION_TOKEN | GitLab runner registration token for GITLAB_NAMESPACE                     | yes      |                                  |
| GITLAB_SAMPLE_PROJECT            | Sample project that will be fored to test the runner.                     | no       |                                  |
| GITLAB_SAMPLE_PROJECT_REF        | Ref / branch of the sample project for which a pipeline will be triggers. | no       |                                  |
| GITLAB_URL                       | GitLab url.                                                               | no       | https://www.gitlab.com           |
| AWS_REGION                       | AWS region to be used.                                                    | no       | eu-west-1                        |
| ENVIRONMENT_NAME                 | Name for the enviroment created by the terraform script.                  | no       | terratest-gitlab-runner-<random> |
| RUNNER_NAME                      | Name of the runner that will be created.                                  | no       | terratest-runner                 |


## Test scenario's

### RunnerDefault

- Create runner (terraform init and apply)
- Fork sample project in provided namespace
- Trigger pipeline on provided branch
- Wait for pipeline to succeed.
- Remove forked project
- Cancel spot requests and spot instances
- Remove runners (terraform destroy)

## Run test

Load dependencies
```
dep ensure
```

Run test:
```
go test -v -run TestRunnerDefault
```
