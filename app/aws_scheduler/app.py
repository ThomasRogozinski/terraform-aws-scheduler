import logging
import json
import os
import boto3
from distutils.util import strtobool

from aws_scheduler.asg_worker import ASGWorker
from aws_scheduler.ec2_worker import EC2Worker
from aws_scheduler.rds_worker import RDSWorker

logging.getLogger().setLevel(logging.INFO)

def lambda_handler(event, context):
    # authenticate and post identity
    identity = boto3.client('sts').get_caller_identity()
    logging.info("identity:    {0}".format(identity))

    if ('body' in event):
        data = json.loads(event['body'])['scheduler']
    else:
        data = event['scheduler']
    logging.info("payload:     {0}".format(data))

    aws_region = boto3.session.Session().region_name
    logging.info("region:     {0}".format(aws_region))

    env_var = os.getenv("ENV_VAR")
    logging.info("env_var: {0}".format(env_var))

    action = data['action']
    resources = { 'asg': ASGWorker, 'ec2': EC2Worker, 'rds': RDSWorker }
    tag_list = []

    for tag in data['tags']:
        logging.info("****** processing tag: {0} ***".format(tag))
        aws_tag = { 'Key': tag, 'Values': ['true' if action != 'enable' else 'false'] }
        res_type_list = []

        for resource, worker_class in resources.items():
            if resource in data['resources'] and data['resources'][resource] == True:
                worker = worker_class(aws_region)
                res_list = getattr(worker, action)(aws_tag)
                if len(res_list) > 0: res_type_list.append( { resource: res_list } ) 
            
        if len(res_type_list) > 0: tag_list.append( {tag: res_type_list } )
    
    ret_payload = json.dumps({ "action":  action, "tags": tag_list })
    logging.info("return payload {0}".format(ret_payload))

    return { "statusCode": 200, "body": ret_payload }