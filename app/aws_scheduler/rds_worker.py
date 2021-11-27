import logging
from typing import Dict, List
import boto3
from botocore.exceptions import ClientError
from aws_scheduler.filters import FilterByTags


class RDSWorker(object):
    def __init__(self, region_name=None) -> None:
        if region_name:
            self.rds = boto3.client("rds", region_name=region_name)
        else:
            self.rds = boto3.client("rds")
        self.tag_api = FilterByTags(region_name=region_name)


    def stop(self, aws_tag: Dict) -> None:
        res_list = []
        for cluster_arn in self.tag_api.get_resources("rds:cluster", [aws_tag]):
            cluster_id = cluster_arn.split(":")[-1]
            try:
                self.rds.describe_db_clusters(DBClusterIdentifier=cluster_id)
                self.rds.stop_db_cluster(DBClusterIdentifier=cluster_id)
                res_list.append(cluster_id)
                logging.info("stop rds cluster [{0}]".format(cluster_id))
            except ClientError as ex:
                aws_exception("rds cluster", cluster_id, ex)

        for db_arn in self.tag_api.get_resources("rds:db", [aws_tag]):
            db_id = db_arn.split(":")[-1]
            try:
                self.rds.stop_db_instance(DBInstanceIdentifier=db_id)
                res_list.append(db_id)
                logging.info("stop rds instance [{0}]".format(db_id))
            except ClientError as ex:
                aws_exception("rds instance", db_id, ex)

        return res_list 


    def start(self, aws_tag: Dict) -> None:
        res_list = []
        for cluster_arn in self.tag_api.get_resources("rds:cluster", [aws_tag]):
            cluster_id = cluster_arn.split(":")[-1]
            try:
                self.rds.describe_db_clusters(DBClusterIdentifier=cluster_id)
                self.rds.start_db_cluster(DBClusterIdentifier=cluster_id)
                res_list.append(cluster_id)
                logging.info("start rds cluster [{0}]".format(cluster_id))
            except ClientError as ex:
                aws_exception("rds cluster", cluster_id, ex)

        for db_arn in self.tag_api.get_resources("rds:db", [aws_tag]):
            db_id = db_arn.split(":")[-1]
            try:
                self.rds.start_db_instance(DBInstanceIdentifier=db_id)
                res_list.append(db_id)
                logging.info("start rds instance [{0}]".format(db_id))
            except ClientError as ex:
                aws_exception("rds instance", db_id, ex)

        return res_list 


    def disable(self, aws_tag: Dict) -> None:
        return self.update_tags(aws_tag, 'false')


    def enable(self, aws_tag: Dict) -> None:
        return self.update_tags(aws_tag, 'true')


    def update_tags(self, aws_tag: Dict, new_value: str) -> None:
        res_list = []
        for cluster_arn in self.tag_api.get_resources("rds:cluster", [aws_tag]):
            cluster_id = cluster_arn.split(":")[-1]
            try:
                self.rds.describe_db_clusters(DBClusterIdentifier=cluster_id)
                self.rds.add_tags_to_resource(ResourceName=cluster_arn, Tags=[{ 'Key': aws_tag['Key'], 'Value': new_value }])
                res_list.append(cluster_id)
                logging.info("rds cluster [{0}]".format(cluster_id))
            except ClientError as ex:
                aws_exception("rds cluster", cluster_id, ex)

        for db_arn in self.tag_api.get_resources("rds:db", [aws_tag]):
            db_id = db_arn.split(":")[-1]
            try:
                self.rds.add_tags_to_resource(ResourceName=db_arn, Tags=[{ 'Key': aws_tag['Key'], 'Value': new_value }])
                res_list.append(db_id)
                logging.info("rds instance [{0}]".format(db_id))
            except ClientError as ex:
                aws_exception("rds instance", db_id, ex)

        return res_list 


def aws_exception(resource_name: str, resource_id: str, exception) -> None:
    info_codes = ["InvalidParameterCombination", "DBClusterNotFoundFault"]
    warning_codes = ["InvalidDBClusterStateFault", "InvalidDBInstanceState"]

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
