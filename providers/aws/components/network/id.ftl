[#ftl]
[@addResourceGroupInformation
    type=NETWORK_COMPONENT_TYPE
    attributes=[]
    provider=AWS_PROVIDER
    resourceGroup=DEFAULT_RESOURCE_GROUP
    services=
        [
            AWS_CLOUDWATCH_SERVICE,
            AWS_IDENTITY_SERVICE,
            AWS_VIRTUAL_PRIVATE_CLOUD_SERVICE
        ]
/]

[@addResourceGroupInformation
    type=NETWORK_ACL_COMPONENT_TYPE
    attributes=[]
    provider=AWS_PROVIDER
    resourceGroup=DEFAULT_RESOURCE_GROUP
    services=
        [
            AWS_VIRTUAL_PRIVATE_CLOUD_SERVICE
        ]
/]

[@addResourceGroupInformation
    type=NETWORK_ROUTE_TABLE_COMPONENT_TYPE
    attributes=[]
    provider=AWS_PROVIDER
    resourceGroup=DEFAULT_RESOURCE_GROUP
    services=
        [
            AWS_VIRTUAL_PRIVATE_CLOUD_SERVICE
        ]
/]
