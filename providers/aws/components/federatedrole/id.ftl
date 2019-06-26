[#ftl]
[@addResourceGroupInformation
    type=FEDERATEDROLE_COMPONENT_TYPE
    attributes=[]
    provider=AWS_PROVIDER
    resourceGroup=DEFAULT_RESOURCE_GROUP
    services=
        [
            AWS_COGNITO_SERVICE,
            AWS_SIMPLE_STORAGE_SERVICE,
            AWS_KEY_MANAGEMENT_SERVICE

        ]
/]

[@addResourceGroupInformation
    type=FEDERATEDROLE_ASSIGNMENT_COMPONENT_TYPE
    attributes=[]
    provider=AWS_PROVIDER
    resourceGroup=DEFAULT_RESOURCE_GROUP
    services=
        [
            AWS_IDENTITY_SERVICE
        ]
/]