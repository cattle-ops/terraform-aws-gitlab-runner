#!/usr/bin/env bash

SPOT_REQUESTS=$(aws ec2 describe-spot-instance-requests --filters "Name=state,Values=active,open" | jq -r '[ .SpotInstanceRequests[] | select( .LaunchSpecification.IamInstanceProfile.Name | contains("'$1'")) ]')

echo $SPOT_REQUESTS | jq -r '.[].InstanceId' | xargs aws ec2 terminate-instances --instance-ids
echo $SPOT_REQUESTS | jq -r '.[].SpotInstanceRequestId' | xargs aws ec2 cancel-spot-instance-requests --spot-instance-request-ids