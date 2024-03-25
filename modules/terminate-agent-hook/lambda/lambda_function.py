"""
AWS Lambda function to terminate orphaned GitLab runners and remove unused resources.

- This checks for running GitLab runner instances and terminates them, intended to be triggered by an ASG life cycle
  hook at instance termination.
- Removes all unused SSH keys

https://github.com/cattle-ops/terraform-aws-gitlab-runner/issues/317 has some discussion about this scenario.

This is rudimentary and doesn't check if a build runner has a current job.
"""
import boto3
from botocore.exceptions import ClientError, WaiterError
import json
import os
import sys


def check_runner_running(client, instance_id):
    """
    Checks if the runner instance is running.
    :param client: the boto3 ec2 client
    :param instance_id: the ID of the runner instance
    :return: true or false, whether the runner instance is running
    """
    print(json.dumps({
        "Level": "info",
        "Message": "Looking for running runner instance..."
    }))
    try:
        reservations = client.describe_instances(InstanceIds=[instance_id], Filters=[
            {
                "Name": "instance-state-name",
                "Values": ["running", "pending"],
            }
        ]).get("Reservations")
    except ClientError as error:
        print(json.dumps({
            "Level": "error",
            "Message": "Failed to lookup runner instance"
        }))
        raise error

    if len(reservations) > 0:
        print(json.dumps({
            "Level": "info",
            "Message": "Runner instance still running"
        }))
        return True

    print(json.dumps({
        "Level": "info",
        "Message": "Runner instance already terminated"
    }))
    return False


def stop_runner_service(client, instance_id):
    """
    Stops the gitlab-runner service on the runner instance using SSM command.
    The command may fail if the gitlab-runner service has jobs running, in
    which case the function will error and be re-tried by SQS.
    :param client: the boto3 SSM client
    :param instance_id: the ID of the runner instance
    """
    print(json.dumps({
        "Level": "info",
        "Message": "Stopping gitlab-runner service..."
    }))

    try:
        initial_response = client.send_command(DocumentName=os.environ['DOCUMENT_NAME'],
            Comment="Stop gitlab-runner service, and check whether it's stopped.",
            InstanceIds=[instance_id]
        )
    except ClientError as error:
        print(json.dumps({
            "Level": "error",
            "Message": "Failed to send SSM command"
        }))
        raise error
    
    command_id = initial_response['Command']['CommandId']

    try:
        waiter = client.get_waiter('command_executed')
        waiter.wait(
            CommandId=command_id,
            InstanceId=instance_id,
            WaiterConfig={
                "Delay": 3,
                "MaxAttempts": 10
            }
        )
        command_response = client.get_command_invocation(CommandId=command_id, InstanceId=instance_id)
    except WaiterError as error:
        print(json.dumps({
            "Level": "error",
            "Message": "Failure waiting for command to be successful"
        }))
        raise error

    if command_response['Status'] == "Success":
        print(json.dumps({
            "Level": "info",
            "Message": f"gitlab-runner service stopped, SSM command response: {command_response}"
        }))
    else:
        raise RuntimeError(f"ERROR: gitlab-runner service not stopped, SSM command response: {command_response}")


def ec2_list(client, **args):
    # to be refactored in #631
    # pylint: disable=too-many-branches, too-many-nested-blocks
    """
    List EC2 instances created by the parent GitLab Runner.
    :param client: the boto3 client
    :param args: specify the 'parent' to filter instances created by this Runner
    :return: a list of EC2 instance IDs created by the parent Runner
    """
    print(json.dumps({
        "Level": "info",
        "Message": f"Searching for children of GitLab runner instance {args['parent']}"
    }))

    ec2_instances = client.describe_instances(Filters=[
        {
            "Name": "instance-state-name",
            "Values": ['running', 'pending'],
        },
        {
            "Name": "tag:gitlab-runner-parent-id",
            "Values": ["*"]
        }
    ]).get("Reservations")

    _terminate_list = []
    for _instances in ec2_instances:
        for instance in _instances['Instances']:
            # Get instance name, if set
            _name = None
            for tag in instance['Tags']:
                if tag['Key'] == 'Name':
                    _name = tag['Value']

                if tag['Key'] == 'gitlab-runner-parent-id':
                    if tag['Value'] == args['parent']:
                        # The event data was from this runner's parent
                        print(json.dumps({
                            "Level": "info",
                            "InstanceId": instance['InstanceId'],
                            "Name": _name,
                            "LaunchTime": str(instance['LaunchTime']),
                            "Message": f"{instance['InstanceId']} will be terminated because its parent is terminating."
                        }))
                        _terminate_list.append(instance['InstanceId'])
                    else:
                        try:
                            # Handle other instances without a parent that are still running.
                            _other_child = client.describe_instances(InstanceIds=[tag['Value']])
                            # The specified parent is still in the inventory as 'terminated'
                            if (len(_other_child['Reservations']) > 0):
                                if _other_child['Reservations'][0]['Instances'][0]['State']['Name'] == "terminated":
                                    _terminate_list.append(instance['InstanceId'])
                                    _msg_suffix = "is terminated."
                                else:
                                    continue
                            else:
                                _terminate_list.append(instance['InstanceId'])
                                _msg_suffix = "does not exist."
                        except ClientError as error:
                            if 'InvalidInstanceID.NotFound' in str(error):
                                # The specified parent does not exist
                                _terminate_list.append(instance['InstanceId'])
                                _msg_suffix = "does not exist."
                            else:
                                # Handle any other exception and move on, skipping this instance.
                                print(json.dumps({
                                    "Level": "exception",
                                    "Exception": str(error)
                                }))
                                continue

                        print(json.dumps({
                            "Level": "info",
                            "InstanceId": instance['InstanceId'],
                            "Name": _name,
                            "LaunchTime": str(instance['LaunchTime']),
                            "Message": f"{instance['InstanceId']} appears to be orphaned. Parent runner"
                                       f" {args['parent']} {_msg_suffix}"
                        }))

    return _terminate_list


def cancel_active_spot_requests(ec2_client, executor_name_part):
    """
    Cancel all active spot requests for the given executor name part.
    :param ec2_client: the boto3 EC2 client
    :param executor_name_part: used to filter the spot instance requests by SSH key name to contain this value
    """
    print(json.dumps({
        "Level": "info",
        "Message": f"Removing open spot requests for environment {executor_name_part}"
    }))

    spot_requests_to_cancel = []

    # bandit: there is no hardcoded_password_string issue here
    next_token = ''  # nosec B105
    has_more_spot_requests = True

    while has_more_spot_requests:
        response = ec2_client.describe_spot_instance_requests(Filters=[
            {
                "Name": "state",
                "Values": ['active', 'open']
            },
            {
                "Name": "launch.key-name",
                "Values": ["runner-*"]
            }
        ], MaxResults=1000, NextToken=next_token)

        for spot_request in response["SpotInstanceRequests"]:
            if executor_name_part in spot_request["LaunchSpecification"]["KeyName"]:
                spot_requests_to_cancel.append(spot_request["SpotInstanceRequestId"])

                print(json.dumps({
                    "Level": "info",
                    "Message": f"Identified spot request {spot_request['SpotInstanceRequestId']}"
                }))

        if 'NextToken' in response and response['NextToken']:
            next_token = response['NextToken']
        else:
            has_more_spot_requests = False

    if spot_requests_to_cancel:
        try:
            ec2_client.cancel_spot_instance_requests(SpotInstanceRequestIds=spot_requests_to_cancel)

            print(json.dumps({
                "Level": "info",
                "Message": "Spot requests deleted"
            }))
        except ClientError as error:
            print(json.dumps({
                "Level": "exception",
                "Message": "Bulk cancelling spot requests failed",
                "Exception": str(error)
            }))
    else:
        print(json.dumps({
            "Level": "info",
            "Message": "No spot requests to cancel"
        }))


def remove_unused_ssh_key_pairs(client, executor_name_part):
    """
    Remove all SSH key pairs that are not used by any active Executor EC2 instance.
    :param client: boto3 EC2 client
    :param executor_name_part: used to filter the spot instance requests by SSH key name to contain this value
    """
    print(json.dumps({
        "Level": "info",
        "Message": f"Removing unused SSH key pairs for agent {executor_name_part}"
    }))

    # build list of SSH keys to keep
    paginator = client.get_paginator('describe_instances')
    reservations = paginator.paginate(Filters=[
        {
            "Name": "key-name",
            "Values": ['runner-*'],
        },
        {
            "Name": "instance-state-name",
            "Values": ['pending', 'running'],
        },
    ]).build_full_result().get("Reservations")

    used_key_pairs = []

    for reservation in reservations:
        for instance in reservation["Instances"]:
            used_key_pairs.append(instance['KeyName'])

    all_key_pairs = client.describe_key_pairs(Filters=[
        {
            "Name": "key-name",
            "Values": ['runner-*'],
        },
    ])

    for key_pair in all_key_pairs['KeyPairs']:
        key_name = key_pair['KeyName']

        if key_name not in used_key_pairs:
            # make sure to delete only those keys which belongs to our module
            # unfortunately there are no tags set on the keys and GitLab runner is not able to do that
            if executor_name_part in key_name:
                try:
                    client.delete_key_pair(KeyName=key_name)

                    print(json.dumps({
                        "Level": "info",
                        "Message": f"Key pair deleted: {key_name}"
                    }))
                except ClientError as error:
                    print(json.dumps({
                        "Level": "error",
                        "Message": f"Unable to delete key pair: {key_name}",
                        "Exception": str(error)
                    }))


# context not used: this is the interface for a AWS Lambda function defined by AWS
# pylint: disable=unused-argument
def handler(event, context):
    """
    Main entry point for the lambda function to clean up the resources if an Agent instance is terminated.

    :param event: see https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-concepts.html#gettingstarted-concepts-event
    :param context: see https://docs.aws.amazon.com/lambda/latest/dg/python-context.html
    """

    # if graceful terminate is enabled, then a SQS queue is created to
    # accept messages from the ASG lifecycle hook and trigger this lambda,
    # so the event received by this lambda will be in SQS message format
    #
    # if graceful terminate is disabled then a cloudwatch event rule for
    # the ASG lifecycle hook is created to trigger this lambda, so the
    # event received by this lambda will be in cloudwatch event format
    if os.environ['GRACEFUL_TERMINATE_ENABLED'] == "true":
        message = json.loads(event['Records'][0]['body'])

        region = event['Records'][0]['awsRegion']
        instance_id = message.get("EC2InstanceId")

        if instance_id is None:
            no_instance_id_msg = "No instance ID, skipping"
            print(json.dumps({
                "Level": "info",
                "Message": no_instance_id_msg
            }))
            return no_instance_id_msg

        ec2_client = boto3.client("ec2", region_name=region)
        ssm_client = boto3.client("ssm", region_name=region)
        as_client = boto3.client("autoscaling", region_name=region)

        try:
            if check_runner_running(ec2_client, instance_id):
                stop_runner_service(ssm_client, instance_id)

                print(json.dumps({
                    "Level": "info",
                    "Message": "Completing lifecycle action..."
                }))
                lifecycle_action_response = as_client.complete_lifecycle_action(
                    AutoScalingGroupName=message['AutoScalingGroupName'],
                    LifecycleHookName=message['LifecycleHookName'],
                    LifecycleActionToken=message['LifecycleActionToken'],
                    LifecycleActionResult="CONTINUE"
                )

                print(json.dumps({
                    "Level": "info",
                    "Message": f"CompleteLifecycleAction Successful, response: {lifecycle_action_response}"
                }))
        # catch everything here and log it
        # pylint: disable=broad-exception-caught
        except Exception as ex:
            print(json.dumps({
                "Level": "exception",
                "Exception": str(ex)
            }))

            # if the gitlab-runner service fails to be stopped, the function can error out and the SQS
            # message will go back to the queue to be retried, up to a set amount of times
            message_receive_count = int(event['Records'][0]['attributes']['ApproximateReceiveCount'])
            max_receive_count = int(os.environ['SQS_MAX_RECEIVE_COUNT'])

            print(json.dumps({
                "Level": "info",
                "Message": f"Graceful termination retry count: {message_receive_count}/{max_receive_count}"
            }))
            if message_receive_count < max_receive_count:
                print(json.dumps({
                    "Level": "info",
                    "Message": "Graceful termination will be retried in next function run"
                }))
                sys.exit(1)
            else:
                print(json.dumps({
                    "Level": "info",
                    "Message": "Reached max received count, continuing with instance termination"
                }))
    else:
        event_detail = event['detail']
        instance_id = event_detail['EC2InstanceId']
        region = event['region']

        if event_detail['LifecycleTransition'] != "autoscaling:EC2_INSTANCE_TERMINATING":
            sys.exit()
        
        ec2_client = boto3.client("ec2", region_name=region)
    
    # make sure that no new instances are created
    cancel_active_spot_requests(ec2_client=ec2_client, executor_name_part=os.environ['NAME_EXECUTOR_INSTANCE'])

    # find the executors connected to this agent and terminate them as well
    _terminate_list = ec2_list(client=ec2_client, parent=instance_id)

    if len(_terminate_list) > 0:
        print(json.dumps({
            "Level": "info",
            "Message": f"Terminating instances {', '.join(_terminate_list)}"
        }))
        try:
            ec2_client.terminate_instances(InstanceIds=_terminate_list, DryRun=False)

            print(json.dumps({
                "Level": "info",
                "Message": "Instances terminated"
            }))
        # catch everything here and log it
        # pylint: disable=broad-exception-caught
        except Exception as ex:
            print(json.dumps({
                "Level": "exception",
                "Exception": str(ex)
            }))
    else:
        print(json.dumps({
            "Level": "info",
            "Message": "No instances to terminate."
        }))

    remove_unused_ssh_key_pairs(client=ec2_client, executor_name_part=os.environ['NAME_EXECUTOR_INSTANCE'])

    return "Housekeeping done"


if __name__ == "__main__":
    handler(None, None)
