[#ftl]

[@addComponent
    type=EXTERNALSERVICE_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "An external component which is not part of codeontap"
            }
        ]
    attributes=[]
/]

[@addChildComponent
    type=EXTERNALSERVICE_ENDPOINT_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "An endpoint of an external serivce normally an IP address or collection"
            }
        ]
    attributes=[]
    parent=EXTERNALSERVICE_COMPONENT_TYPE
    childAttribute="Endpoints"
    linkAttributes="Endpoint"
/]

[@addResourceGroupInformation
    type=EXTERNALSERVICE_COMPONENT_TYPE
    attributes=[
        {
            "Names" : "DeploymentGroup",
            "Type" : STRING_TYPE,
            "Default" : "external"
        },
        {
            "Names" : "Properties",
            "Subobjects" : true,
            "Children" : [
                {
                    "Names" : "Key",
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Value",
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                }
            ]
        },
        {
            "Names" : ["Fragment", "Container"],
            "Type" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "Links",
            "Subobjects" : true,
            "Children" : linkChildrenConfiguration
        }
    ]
    provider=SHARED_PROVIDER
    resourceGroup=DEFAULT_RESOURCE_GROUP
    services=[
        SHARED_EXTERNAL_SERVICE
    ]
/]


[@addResourceGroupInformation
    type=EXTERNALSERVICE_ENDPOINT_COMPONENT_TYPE
    attributes=[
            {
                "Names" : "IPAddressGroups",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Port",
                "Type" : STRING_TYPE,
                "Default" : ""
            }
        ]
    provider=SHARED_PROVIDER
    resourceGroup=DEFAULT_RESOURCE_GROUP
    services=[
        SHARED_EXTERNAL_SERVICE
    ]
/]
