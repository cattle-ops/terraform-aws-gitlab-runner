# Provide the parent instance id in the spawned runner tags
PARENT_INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id);
PARENT_TAG="gitlab-runner-parent-id,$${PARENT_INSTANCE_ID}"

mkdir -p /etc/gitlab-runner
cat > /etc/gitlab-runner/config.toml <<- EOF

${runners_config}

EOF

sed -i.bak s/__PARENT_TAG__/`echo $PARENT_TAG`/g /etc/gitlab-runner/config.toml

${pre_install}

if [[ `echo ${runners_executor}` == "docker" ]]
then
  echo 'installing docker'
  if grep -q ':2$' /etc/system-release-cpe  ; then
    # AWS Linux 2 provides docker via extras only and uses systemd (https://aws.amazon.com/amazon-linux-2/release-notes/)
    amazon-linux-extras install docker
    usermod -a -G docker ec2-user
    systemctl enable docker
    systemctl start docker
  else
    yum install docker -y
    usermod -a -G docker ec2-user
    service docker start
  fi
fi

if [[ `echo ${runners_install_amazon_ecr_credential_helper}` == "true" ]]
then
  yum install amazon-ecr-credential-helper -y
fi

if ! ( rpm -q gitlab-runner >/dev/null )
then
  curl --fail --retry 6 -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | bash
  yum install gitlab-runner-${gitlab_runner_version} -y
fi

if [[ `echo ${docker_machine_download_url}` == "" ]]
then
  curl --fail --retry 6 -L https://gitlab-docker-machine-downloads.s3.amazonaws.com/v${docker_machine_version}/docker-machine-`uname -s`-`uname -m` >/tmp/docker-machine
else
  curl --fail --retry 6 -L ${docker_machine_download_url} >/tmp/docker-machine
fi

chmod +x /tmp/docker-machine && \
  mv /tmp/docker-machine /usr/local/bin/docker-machine && \
  ln -s /usr/local/bin/docker-machine /usr/bin/docker-machine
docker-machine --version

# Create a dummy machine so that the cert is generated properly
# See: https://gitlab.com/gitlab-org/gitlab-runner/issues/3676
# See: https://github.com/docker/machine/issues/3845#issuecomment-280389178
export USER=root
export HOME=/root
docker-machine create --driver none --url localhost dummy-machine
docker-machine rm -y dummy-machine
unset HOME
unset USER

# Install jq if not exists
if ! [ -x "$(command -v jq)" ]; then
  yum install jq -y
fi

# fetch Runner token from SSM and validate it
token=$(aws ssm get-parameters --names "${secure_parameter_store_runner_token_key}" --with-decryption --region "${secure_parameter_store_region}" | jq -r ".Parameters | .[0] | .Value")

valid_token=true
if [[ `echo $token` != "null" ]]
then
  valid_token_response=$(curl -s -o /dev/null -w "%%{response_code}" --request POST -L "${runners_gitlab_url}/api/v4/runners/verify" --form "token=$token" )
  [[ `echo $valid_token_response` != "200" ]] && valid_token=false
fi

if [[ `echo ${runners_token}` == "__REPLACED_BY_USER_DATA__" && `echo $token` == "null" ]] || [[ `echo $valid_token` == "false" ]]
then
  token=$(curl --request POST -L "${runners_gitlab_url}/api/v4/runners" \
    --form "token=${gitlab_runner_registration_token}" \
    --form "tag_list=${gitlab_runner_tag_list}" \
    --form "description=${giltab_runner_description}" \
    --form "locked=${gitlab_runner_locked_to_project}" \
    --form "run_untagged=${gitlab_runner_run_untagged}" \
    --form "maximum_timeout=${gitlab_runner_maximum_timeout}" \
    --form "access_level=${gitlab_runner_access_level}" \
    | jq -r .token)
  aws ssm put-parameter --overwrite --type SecureString  --name "${secure_parameter_store_runner_token_key}" --value="$token" --region "${secure_parameter_store_region}"
fi

sed -i.bak s/__REPLACED_BY_USER_DATA__/`echo $token`/g /etc/gitlab-runner/config.toml

ssm_sentry_dsn=$(aws ssm get-parameters --names "${secure_parameter_store_runner_sentry_dsn}" --with-decryption --region "${secure_parameter_store_region}" | jq -r ".Parameters | .[0] | .Value")
if [[ `echo ${sentry_dsn}` == "__SENTRY_DSN_REPLACED_BY_USER_DATA__" && `echo $ssm_sentry_dsn` == "null" ]]
then
  ssm_sentry_dsn=""
fi

# For those of you wondering why commas are used in the sed below instead of forward slashes, see https://stackoverflow.com/a/16778711/13169919
# It is because the Sentry DSN contains forward slashes as it is an URL so it would break out of the sed command with forward slashes as delimiters :)
sed -i.bak s,__SENTRY_DSN_REPLACED_BY_USER_DATA__,`echo $ssm_sentry_dsn`,g /etc/gitlab-runner/config.toml

# A small script to remove this runner from being registered with Gitlab.
cat <<REM > /etc/rc.d/init.d/remove_gitlab_registration
#!/bin/bash
# chkconfig: 1356 99 03
# description: cleans up gitlab runner key
# processname: remove_runner_key
#              /etc/rc.d/init.d/remove_gitlab_registration
lockfile=/var/lock/subsys/remove_gitlab_registration

# This lockfile is necessary so that we'll run the cleanup later.
start() {
    logger "Setting up Runner Removal Lockfile"
    touch \$lockfile
}

# Overwrite token in SSM with null and remove runner from Gitlab
stop() {
    logger "Removing Gitlab Runner Token"
    aws ssm put-parameter --overwrite --type SecureString  --name "${secure_parameter_store_runner_token_key}" --region "${secure_parameter_store_region}" --value="null" 2>&1 | logger &
    curl -sS --request DELETE "${runners_gitlab_url}/api/v4/runners" --form "token=$token" 2>&1 | logger &
    retval=\$?
    rm -f \$lockfile
    return \$retval
}

# Map these to start just to be redunant.
# We don't want to run Stop outside of shutdown.
restart() {
  start
}
reload() {
  start
}

# Do nothing - there's no status.
status() {
  :
}

case "\$1" in
    start)
        \$1
        ;;
    stop)
        \$1
        ;;
    restart)
        \$1
        ;;
    status)
        \$1
        ;;
    *)
        echo "Usage: \$0 {start|stop|status|restart}"
        exit 2
        ;;
esac
REM

chmod a+x /etc/init.d/remove_gitlab_registration

# Use chkconfig to link into the runlevel 0 (shutdown) directories
# This adds "start" scripts to levels 1,3,5, and 6, and a "stop" to the others.
# This way we'll not be assigned jobs if we're shutting down, and clean up in Gitlab.
chkconfig --add remove_gitlab_registration

# As noted above, this does nothing more than make the lockfile.
service remove_gitlab_registration start

${post_install}

service gitlab-runner restart
chkconfig gitlab-runner on
