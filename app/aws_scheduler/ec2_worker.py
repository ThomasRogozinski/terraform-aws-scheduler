import logging
from typing import Dict, List
import boto3
from botocore.exceptions import ClientError
from aws_scheduler.filters import FilterByTags


class EC2Worker(object):
    def __init__(self, region_name=None) -> None:
        if region_name:
            self.ec2 = boto3.client("ec2", region_name=region_name)
            self.asg = boto3.client("autoscaling", region_name=region_name)
        else:
            self.ec2 = boto3.client("ec2")
            self.asg = boto3.client("autoscaling")
        self.tag_api = FilterByTags(region_name=region_name)


    def stop(self, aws_tag: Dict) -> None:
        res_list = []
        for instance_arn in self.tag_api.get_resources("ec2:instance", [aws_tag]):
            instance_id = instance_arn.split("/")[-1]
            try:
                if not self.asg.describe_auto_scaling_instances(InstanceIds=[instance_id])["AutoScalingInstances"]:
                    self.ec2.stop_instances(InstanceIds=[instance_id])
                    res_list.append(instance_id)
                    logging.info("stop ec2 [{0}]".format(instance_id))
            except ClientError as ex:
                aws_exception("ec2", instance_id, ex)

        return res_list 


    def start(self, aws_tag: Dict) -> None:
        res_list = []
        for instance_arn in self.tag_api.get_resources("ec2:instance", [aws_tag]):
            instance_id = instance_arn.split("/")[-1]
            try:
                if not self.asg.describe_auto_scaling_instances(InstanceIds=[instance_id])["AutoScalingInstances"]:
                    self.ec2.start_instances(InstanceIds=[instance_id])
                    res_list.append(instance_id)
                    logging.info("start ec2 [{0}]".format(instance_id))
            except ClientError as ex:
                aws_exception("ec2", instance_id, ex)

        return res_list 


    def disable(self, aws_tag: Dict) -> None:
        return self.update_tags(aws_tag, 'false')


    def enable(self, aws_tag: Dict) -> None:
        return self.update_tags(aws_tag, 'true')


    def update_tags(self, aws_tag: Dict, new_value: str) -> None:
        res_list = []
        for instance_arn in self.tag_api.get_resources("ec2:instance", [aws_tag]):
            instance_id = instance_arn.split("/")[-1]
            try:
                if not self.asg.describe_auto_scaling_instances(InstanceIds=[instance_id])["AutoScalingInstances"]:
                    self.ec2.create_tags(Resources=[instance_id], Tags=[{ 'Key': aws_tag['Key'], 'Value': new_value }])
                    res_list.append(instance_id)
                    logging.info("ec2 [{0}]".format(instance_id))
            except ClientError as ex:
                aws_exception("ec2", instance_id, ex)

        return res_list 



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
