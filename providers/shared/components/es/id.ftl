[#ftl]

[@addComponent
    type=ES_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A managed ElasticSearch instance"
            }
        ]
    attributes=
        [
            {
                "Names" : "Authentication",
                "Types" : STRING_TYPE,
                "Values" : ["IP", "SIG4ORIP", "SIG4ANDIP"],
                "Default" : "IP"
            },
            {
                "Names" : "IPAddressGroups",
                "Description" : "A list of IP Address Groups which will be permitted to access the ES index",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : [ "MultiAZ", "MultiZone"],
                "Description" : "Deploy resources to multiple Availablity Zones",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "AdvancedOptions",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "Id",
                        "Types" : STRING_TYPE
                    },
                    {
                        "Names" : "Value",
                        "Types" : STRING_TYPE
                    }
                ]
            },
            {
                "Names" : "Version",
                "Types" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "Encrypted",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Snapshot",
                "Children" : [
                    {
                        "Names" : "Hour",
                        "Types" : STRING_TYPE,
                        "Default" : ""
                    }
                ]
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Profiles",
                "Children" :
                    [
                        {
                            "Names" : "Processor",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Storage",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Alert",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Security",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Network",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Logging",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
            },
            {
                "Names" : "Alerts",
                "SubObjects" : true,
                "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Logging",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AllowMajorVersionUpdates",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "VPCAccess",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            }
        ]
/]

[@addComponentDeployment
    type=ES_COMPONENT_TYPE
    defaultGroup="solution"
/]
