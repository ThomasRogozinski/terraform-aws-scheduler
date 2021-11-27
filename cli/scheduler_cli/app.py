import boto3
import json
import sys
from args_parser import parse_arguments
from input_parser import parse_input, select_choice


def main(args):
    lambda_payload = { 
        "scheduler": {
            "action": args.action,
            "resources": {
                "ec2": args.ec2,
                "asg": args.asg,
                "rds": args.rds
            },
            "tags": args.tags
        }
    }
    print("\nrequest function: {0}".format(args.name))
    print("request payload: {0}".format(json.dumps(lambda_payload, indent=4)))

    boto3.setup_default_session()
    lambda_client = boto3.client('lambda')
    response = lambda_client.invoke(FunctionName = args.name, 
        InvocationType ='RequestResponse',
        Payload=json.dumps(lambda_payload))

    print(response)
    # print formatted and indented json
    resp = json.loads(response['Payload'].read().decode('utf-8'))
    print("\nresponse status: {0}".format(resp['statusCode']))
    print("response payload: {0}".format(json.dumps(json.loads(resp['body']), indent=4)))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        args = parse_input()
    else:
        args = parse_arguments()
        
    main(args)
