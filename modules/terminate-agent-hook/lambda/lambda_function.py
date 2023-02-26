"""
AWS Lambda function to terminate orphaned GitLab runners and remove unused resources.

- This checks for running GitLab runner instances and terminates them, intended to be triggered by an ASG life cycle hook at
  instance termination.
- Removes all unused SSH keys

https://github.com/npalm/terraform-aws-gitlab-runner/issues/317 has some discussion about this scenario.

This is rudimentary and doesn't check if a build runner has a current job.
"""
import boto3
import botocore
import json
import os


def ec2_list(client, **args):
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
                        except Exception as e:
                            if 'InvalidInstanceID.NotFound' in str(e):
                                # The specified parent does not exist
                                _terminate_list.append(instance['InstanceId'])
                                _msg_suffix = "does not exist."
                            else:
                                # Handle any other excpetion and move on, skipping this instance.
                                print(json.dumps({
                                    "Level": "exception",
                                    "Exception": str(e)
                                }))
                                continue

                        print(json.dumps({
                            "Level": "info",
                            "InstanceId": instance['InstanceId'],
                            "Name": _name,
                            "LaunchTime": str(instance['LaunchTime']),
                            "Message": f"{instance['InstanceId']} appears to be orphaned. Parent runner {args['parent']} {_msg_suffix}"
                        }))

    return _terminate_list


def remove_unused_ssh_key_pairs(client, executor_name_part):
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
                except botocore.exceptions.ClientError as error:
                    print(json.dumps({
                        "Level": "error",
                        "Message": f"Unable to delete key pair: {key_name}",
                        "Exception": str(error)
                    }))


def handler(event, context):
    response = []
    event_detail = event['detail']
    client = boto3.client("ec2", region_name=event['region'])
    if event_detail['LifecycleTransition'] != "autoscaling:EC2_INSTANCE_TERMINATING":
        exit()

    # find the executors connected to this agent and terminate them as well
    _terminate_list = ec2_list(client=client, parent=event_detail['EC2InstanceId'])
    if len(_terminate_list) > 0:
        print(json.dumps({
            "Level": "info",
            "Message": f"Terminating instances {', '.join(_terminate_list)}"
        }))
        try:
            client.terminate_instances(InstanceIds=_terminate_list, DryRun=False)
        except Exception as e:
            print(json.dumps({
                "Level": "exception",
                "Exception": str(e)
            }))
    else:
        print(json.dumps({
            "Level": "info",
            "Message": "No instances to terminate."
        }))

    remove_unused_ssh_key_pairs(client=client, executor_name_part=os.environ['NAME_EXECUTOR_INSTANCE'])

    return f"Housekeeping done"


if __name__ == "__main__":
    handler(None, None)
