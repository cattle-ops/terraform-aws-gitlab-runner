package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"log"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"

	"github.com/joho/godotenv"
	"github.com/npalm/terraform-aws-gitlab-runner/test/config"
	"github.com/xanzy/go-gitlab"
)

var git *gitlab.Client
var project *gitlab.Project
var pipeline *gitlab.Pipeline
var conf *config.Config

func init() {
	// loads values from .env into the system
	if err := godotenv.Load(); err != nil {
		log.Print("No .env file found")
	}
	conf = config.New()

}

func TestRunnerDefault(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/runner-default",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"environment":        conf.EnvironmentName,
			"aws_region":         conf.AwsRegion,
			"runner_name":        conf.RunnerName,
			"registration_token": conf.GitlabConfig.GitlabRunnerRegistrationToken,
			"gitlab_url":         conf.GitlabConfig.GitlabURL,
		},

		// Environment variables to set when running Terraform
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": conf.AwsRegion,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	git = gitlab.NewClient(nil, conf.GitlabConfig.GitlabAccessToken)

	p, _, err := git.Projects.ForkProject(conf.GitlabConfig.GitlabSampleProject, &gitlab.ForkProjectOptions{
		Namespace: &conf.GitlabConfig.GitlabNamespace,
	})
	// set global project var
	project = p
	logger.Log(t, fmt.Sprintf("Created fork : %s", project.NameWithNamespace))
	defer git.Projects.DeleteProject(project.ID)

	// wait a few seconds to ensure project is forked
	time.Sleep(5 * time.Second)

	// trigger pipelins
	pipeline, _, err = git.Pipelines.CreatePipeline(project.ID, &gitlab.CreatePipelineOptions{
		Ref: &conf.GitlabConfig.GitlabSampleProjectRef,
	})

	// wait till pipeline succeeds
	pipelineSuccess, err := waitAndRetry(t, checkPipeline, RetryOptions{
		waitTime:   2 * 1000, // 2 seconds
		maxRetries: 300,      // 10 minutes
	})
	assert.True(t, pipelineSuccess)

	if err != nil {
		log.Fatal("Something wrong :( - TODO handle errors", err)
		return
	}

}

type RetryOptions struct {
	maxRetries int
	attempts   int
	waitTime   int
	backOff    int
}

func checkPipeline(t *testing.T) (result bool, err error) {
	p, _, err := git.Pipelines.GetPipeline(project.ID, pipeline.ID)
	logger.Log(t, fmt.Sprintf("Waiting for pipeline, status: `%s`. See: `%s`", p.Status, p.WebURL))
	return p.Status == "success", err
}

type Func func(t *testing.T) (retry bool, err error)

func waitAndRetry(t *testing.T, fn Func, options RetryOptions) (result bool, err error) {
	if options.backOff == 0 {
		options.backOff = 1
	}

	result, err = fn(t)
	retry := !result && (err == nil)
	retry = retry && (options.maxRetries == 0 || options.attempts < options.maxRetries)
	if retry {
		options.waitTime = options.waitTime * options.backOff
		options.attempts++
		time.Sleep(time.Duration(options.waitTime) * time.Millisecond)
		result, err = waitAndRetry(t, fn, options)
	}
	return result, err
}
