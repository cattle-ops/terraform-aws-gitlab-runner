# ----------------------------------------------------------------------------
# Graceful Terminate - SQS Resources
# ----------------------------------------------------------------------------

resource "aws_ssm_document" "stop_gitlab_runner" {
  count = var.graceful_terminate_enabled ? 1 : 0

  name            = "${var.environment}-stop-gitlab-runner"
  document_format = "YAML"
  document_type   = "Command"

  content = <<DOC
schemaVersion: "2.2"
description: "Stops the gitlab-runner service, checks if service is stopped."
parameters: {}
mainSteps:
  - action: "aws:runShellScript"
    name: "StopGitLabRunner"
    inputs:
      runCommand:
        - systemctl --no-block stop gitlab-runner.service
        - sleep 5
        - status=$(systemctl is-active gitlab-runner.service)
        - |
          if [ "$status" == "inactive" ]
          then
            echo "gitlab-runner service stopped"
            machines=$(sudo docker-machine ls -q)
            if [ -n "$machines" ]; then
              if sudo docker-machine rm -y $machines; then
                echo "removed docker machines"
              else
                echo "failed to remove docker machines"
                exit 1
              fi
            fi
            exit 0
          else
            echo "gitlab-runner service not stopped" 1>&2
            exit 1
          fi
DOC

  tags = var.tags
}
