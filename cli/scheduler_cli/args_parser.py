import sys
import argparse

def parse_arguments():
    try:
        parser = argparse.ArgumentParser(description="Invoke Lambda Scheduler")
        parser.add_argument('-n', '--name', help='name of the lambda function to trigger', required=True)
        parser.add_argument('-a', '--action', choices=['start', 'stop', 'enable', 'disable'], help='action to trigger', required=True)
        parser.add_argument('-e', '--ec2', action='store_true', default=False, help='process ec2', required=False)
        parser.add_argument('-g', '--asg', action='store_true', default=False, help='process asg', required=False)
        parser.add_argument('-r', '--rds', action='store_true', default=False, help='process rds', required=False)
        parser.add_argument('-t','--tags', nargs='+', help='resource tags to act on', required=True)
        return parser.parse_args()
    except Exception as ex:
        print(ex)
        sys.exit(0)