from typing import Iterator
import boto3


class FilterByTags(object):
    def __init__(self, region_name=None) -> None:
        if region_name:
            self.rgta = boto3.client("resourcegroupstaggingapi", region_name=region_name)
        else:
            self.rgta = boto3.client("resourcegroupstaggingapi")

    def get_resources(self, resource_type, aws_tags) -> Iterator[str]:
        paginator = self.rgta.get_paginator("get_resources")
        page_iterator = paginator.paginate(TagFilters=aws_tags, ResourceTypeFilters=[resource_type])

        for page in page_iterator:
            for resource_tag_map in page["ResourceTagMappingList"]:
                yield resource_tag_map["ResourceARN"]
