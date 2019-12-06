[#ftl]

[@addComponent
    type=EXTERNALSERVICE_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "An external component which is not part of codeontap"
            },
            {
                "Type" : "Providers",
                "Value" : [ "shared" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "solution"
            }
        ]
    attributes=[]
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
        }
    ]
    provider=SHARED_PROVIDER
    resourceGroup=DEFAULT_RESOURCE_GROUP
    services=[
        SHARED_EXTERNAL_SERVICE
    ]
/]
