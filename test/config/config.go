package config

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/random"
	"os"
)

// Config ...
type Config struct {
	GitlabConfig    GitlabConfig
	AwsRegion       string
	RunnerName      string
	EnvironmentName string
}

// GitlabConfig ...
type GitlabConfig struct {
	GitlabAccessToken             string
	GitlabRunnerRegistrationToken string
	GitlabURL                     string
	GitlabSampleProject           string
	GitlabNamespace               string
	GitlabSampleProjectRef        string
}

// New returns a new Config struct
func New() *Config {
	return &Config{
		GitlabConfig: GitlabConfig{
			GitlabAccessToken:             getEnv("GITLAB_ACCESS_TOKEN", ""),
			GitlabRunnerRegistrationToken: getEnv("GITLAB_RUNNER_REGISTRATION_TOKEN", ""),
			GitlabURL:                     getEnv("GITLAB_URL", "https://www.gitlab.com"),
			GitlabSampleProject:           getEnv("GITLAB_SAMPLE_PROJECT", "4742712"),
			GitlabSampleProjectRef:        getEnv("GITLAB_SAMPLE_PROJECT_REF", "master"),
			GitlabNamespace:               getEnv("GITLAB_NAMESPACE", ""),
		},
		AwsRegion:       getEnv("AWS_REGION", "eu-west-1"),
		RunnerName:      getEnv("RUNNER_NAME", "terratest-runner"),
		EnvironmentName: getEnv("ENVIRONMENT_NAME", fmt.Sprintf("terratest-gitlab-runner-%s", random.UniqueId())),
	}

}

func getEnv(key string, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}

	return defaultValue
}
