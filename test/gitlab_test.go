package test

import (
	"fmt"
	"log"
	"strings"
	"terratest/modules/logger"
	"terratest/modules/terraform"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
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
	retry(t, checkPipeline, RetryOptions{
		waitTime: 2 * 1000,
	})

	// Create AWS session
	awsSession, err := session.NewSession(&aws.Config{
		Region: aws.String(conf.AwsRegion)},
	)
	svc := ec2.New(awsSession)

	// delete spot requests and instances
	err = cancelSpotRequests(t, svc, conf.EnvironmentName)

	if err != nil {
		log.Fatal("Something wrong :( - TODO handle errors", err)
		return
	}

}

func cancelSpotRequests(t *testing.T, svc *ec2.EC2, environmentName string) (err error) {
	spot, err := svc.DescribeSpotInstanceRequests(&ec2.DescribeSpotInstanceRequestsInput{})

	for _, s := range spot.SpotInstanceRequests {
		if strings.HasPrefix(*s.LaunchSpecification.IamInstanceProfile.Name, environmentName) {
			logger.Log(t, fmt.Sprintf("Cancel sport request and terminatie instance : %s", *s.InstanceId))

			_, err = svc.CancelSpotInstanceRequests(&ec2.CancelSpotInstanceRequestsInput{
				SpotInstanceRequestIds: aws.StringSlice([]string{*s.SpotInstanceRequestId}),
			})
			_, err = svc.TerminateInstances(&ec2.TerminateInstancesInput{
				InstanceIds: aws.StringSlice([]string{*s.InstanceId}),
			})

		}
	}
	return err

}

type RetryOptions struct {
	maxRetries int
	attempts   int
	waitTime   int
	backOff    int
}

func checkPipeline(t *testing.T) (result bool, err error) {
	p, _, err := git.Pipelines.GetPipeline(project.ID, pipeline.ID)
	logger.Log(t, fmt.Sprintf("Waiting for pipeline, current status: `%s`. Check on GitLab: `%s`", p.Status, p.WebURL))
	return p.Status == "success", err
}

type Func func(t *testing.T) (retry bool, err error)

func retry(t *testing.T, fn Func, options RetryOptions) (err error) {
	if options.backOff == 0 {
		options.backOff = 1
	}

	r, err := fn(t)
	if !r && (options.maxRetries == 0 || options.attempts < options.maxRetries) {
		options.waitTime = options.waitTime * options.backOff
		options.attempts++
		time.Sleep(time.Duration(options.waitTime) * time.Millisecond)
		retry(t, fn, options)
	}
	return err
}
