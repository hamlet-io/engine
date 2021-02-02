[#ftl]

[@addComponentDeployment
    type=EXTERNALSERVICE_COMPONENT_TYPE
    defaultGroup="external"
/]

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
            "Names" : "Properties",
            "Subobjects" : true,
            "Children" : [
                {
                    "Names" : "Key",
                    "Types" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Value",
                    "Types" : STRING_TYPE,
                    "Mandatory" : true
                }
            ]
        },
        {
            "Names" : [ "Extensions", "Fragment", "Container" ],
            "Description" : "Extensions to invoke as part of component processing",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "Links",
            "Subobjects" : true,
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
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
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Port",
                "Types" : STRING_TYPE,
                "Default" : ""
            }
        ]
    provider=SHARED_PROVIDER
    resourceGroup=DEFAULT_RESOURCE_GROUP
    services=[
        SHARED_EXTERNAL_SERVICE
    ]
/]
