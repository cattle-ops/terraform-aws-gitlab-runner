#!/usr/bin/env sh

hash jq aws &>/dev/null || {
    echo >&2 "I require jq and AWS CLI but one or both is not installed.  Aborting."
    exit 1
}

SPOT_REQUESTS=$(aws ec2 describe-spot-instance-requests --filters "Name=state,Values=active,open" | jq -r '[ .SpotInstanceRequests[] | select( .LaunchSpecification.IamInstanceProfile.Name | contains("'$1'")) ]')

# It's possible there's no spot requests to cancel, so be safe.
if [ "${SPOT_REQUESTS}" != "[]" ]; then
    echo $SPOT_REQUESTS | jq -r '.[].InstanceId' | xargs aws ec2 terminate-instances --instance-ids
    echo $SPOT_REQUESTS | jq -r '.[].SpotInstanceRequestId' | xargs aws ec2 cancel-spot-instance-requests --spot-instance-request-ids
else
    # If there's no instances to kill, just log out that and return happy.
    echo "Found no spot instances to kill or requests to cancel."
    exit 0
fi
