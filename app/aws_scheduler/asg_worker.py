import logging
from typing import Dict, Iterator, List
import boto3
from botocore.exceptions import ClientError


class ASGWorker(object):
    def __init__(self, region_name=None) -> None:
        if region_name:
            self.ec2 = boto3.client("ec2", region_name=region_name)
            self.asg = boto3.client("autoscaling", region_name=region_name)
        else:
            self.ec2 = boto3.client("ec2")
            self.asg = boto3.client("autoscaling")


    def stop(self, aws_tag: Dict) -> None:
        tag_key = aws_tag["Key"]
        for tag_value in aws_tag["Values"]:
            asg_name_list = self.list_groups(tag_key, tag_value)
            instance_id_list = self.list_instances(asg_name_list)
            res_list = []

            for asg_name in asg_name_list:
                try:
                    self.asg.suspend_processes(AutoScalingGroupName=asg_name)
                    res_list.append(asg_name)
                    logging.info("stop asg grp [{0}]".format(asg_name))
                except ClientError as ex:
                    aws_exception("asg grp", asg_name, ex)

            for instance_id in instance_id_list:
                try:
                    self.ec2.stop_instances(InstanceIds=[instance_id])
                    res_list.append(instance_id)
                    logging.info("stop asg ec2 [{0}]".format(instance_id))
                except ClientError as ex:
                    aws_exception("asg ec2", instance_id, ex)
            
            return res_list 


    def start(self, aws_tag: Dict) -> None:
        tag_key = aws_tag["Key"]
        for tag_value in aws_tag["Values"]:
            asg_name_list = self.list_groups(tag_key, tag_value)
            instance_id_list = self.list_instances(asg_name_list)
            instance_running_ids = []
            res_list = []

            for instance_id in instance_id_list:
                try:
                    self.ec2.start_instances(InstanceIds=[instance_id])
                    res_list.append(instance_id)
                    logging.info("start asg ec2 [{0}]".format(instance_id))
                except ClientError as ex:
                    aws_exception("asg ec2", instance_id, ex)
                else:
                    instance_running_ids.append(instance_id)
            try:
                self.instance_running(instance_ids=instance_running_ids)
            except Exception as ex:
                aws_exception("asg waiters", ' '.join(instance_running_ids), ex)

            for asg_name in asg_name_list:
                try:
                    self.asg.resume_processes(AutoScalingGroupName=asg_name)
                    res_list.append(asg_name)
                    logging.info("start asg grp [{0}]".format(asg_name))
                except ClientError as ex:
                    aws_exception("asg grp", asg_name, ex)

            return res_list 


    def disable(self, aws_tag: Dict) -> None:
        return self.update_tags(aws_tag, 'false')


    def enable(self, aws_tag: Dict) -> None:
        return self.update_tags(aws_tag, 'true')


    def update_tags(self, aws_tag: Dict, new_value: str) -> None:
        tag_key = aws_tag["Key"]
        for tag_value in aws_tag["Values"]:
            asg_name_list = self.list_groups(tag_key, tag_value)
            instance_id_list = self.list_instances(asg_name_list)
            res_list = []

            for asg_name in asg_name_list:
                try:
                    self.asg.create_or_update_tags(Tags=[{ 'ResourceId': asg_name, 'ResourceType': 'auto-scaling-group', 'Key': aws_tag['Key'], 'Value': new_value, 'PropagateAtLaunch': True }])
                    res_list.append(asg_name)
                    logging.info("asg grp [{0}]".format(asg_name))
                except ClientError as ex:
                    aws_exception("asg grp", asg_name, ex)

            for instance_id in instance_id_list:
                try:
                    self.ec2.create_tags(Resources=[instance_id], Tags=[{ 'Key': aws_tag['Key'], 'Value': new_value }])
                    res_list.append(instance_id)
                    logging.info("asg ec2 [{0}]".format(instance_id))
                except ClientError as ex:
                    aws_exception("asg ec2", instance_id, ex)

        return res_list 
 

    def list_groups(self, tag_key: str, tag_value: str) -> List[str]:
        asg_name_list = []
        paginator = self.asg.get_paginator("describe_auto_scaling_groups")

        for page in paginator.paginate():
            for group in page["AutoScalingGroups"]:
                for tag in group["Tags"]:
                    if tag["Key"] == tag_key and tag["Value"] == tag_value:
                        asg_name_list.append(group["AutoScalingGroupName"])
        return asg_name_list


    def list_instances(self, asg_name_list: List[str]) -> Iterator[str]:
        if not asg_name_list:
            return iter([])
        paginator = self.asg.get_paginator("describe_auto_scaling_groups")

        for page in paginator.paginate(AutoScalingGroupNames=asg_name_list):
            for scalinggroup in page["AutoScalingGroups"]:
                for instance in scalinggroup["Instances"]:
                    yield instance["InstanceId"]


    def instance_running(self, instance_ids: List[str]) -> None:
        if instance_ids:
            try:
                instance_waiter = self.ec2.get_waiter("instance_running")
                instance_waiter.wait(
                    InstanceIds=instance_ids,
                    WaiterConfig={"Delay": 15, "MaxAttempts": 15},
                )
            except ClientError as ex:
                aws_exception("waiter", instance_waiter, ex)


def aws_exception(resource_name: str, resource_id: str, exception) -> None:
    info_codes = ["IncorrectInstanceState"]
    warning_codes = [
        "UnsupportedOperation",
        "IncorrectInstanceState",
        "InvalidParameterCombination",
    ]

    if exception.response["Error"]["Code"] in info_codes:
        logging.info(
            "%s %s: %s",
            resource_name,
            resource_id,
            exception,
        )
    elif exception.response["Error"]["Code"] in warning_codes:
        logging.warning(
            "%s %s: %s",
            resource_name,
            resource_id,
            exception,
        )
    else:
        logging.error(
            "Unexpected error on %s %s: %s",
            resource_name,
            resource_id,
            exception,
        )
