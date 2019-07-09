[#ftl]

[@addComponent
    type=ES_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A managed ElasticSearch instance"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "solution"
            }
        ]
    attributes=
        [
            {
                "Names" : "Authentication",
                "Type" : STRING_TYPE,
                "Values" : ["IP", "SIG4ORIP", "SIG4ANDIP"],
                "Default" : "IP"
            },
            {
                "Names" : "Accounts",
                "Description" : "A list of accounts which will be permitted to access the ES index",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "_environment" ]
            },
            {
                "Names" : "IPAddressGroups",
                "Description" : "A list of IP Address Groups which will be permitted to access the ES index",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "AdvancedOptions",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Version",
                "Type" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "Encrypted",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Snapshot",
                "Children" : [
                    {
                        "Names" : "Hour",
                        "Type" : STRING_TYPE,
                        "Default" : ""
                    }
                ]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "Profiles",
                "Children" :
                    [
                        {
                            "Names" : "Processor",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Alert",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
            },
            {
                "Names" : "Alerts",
                "Subobjects" : true,
                "Children" : alertChildrenConfiguration
            }
        ]
/]
