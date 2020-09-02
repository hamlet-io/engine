[#ftl]

[@addComponentDeployment
    type=CACHE_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addComponent
    type=CACHE_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Managed in-memory cache services"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Type" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "EngineVersion",
                "Type" : STRING_TYPE
            },
            {
                "Names" : "Port",
                "Type" : STRING_TYPE
            },
            {
                "Names" : "IPAddressGroups",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "_localnet" ]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "Backup",
                "Children" : [
                    {
                        "Names" : "RetentionPeriod",
                        "Type" : STRING_TYPE,
                        "Default" : ""
                    }
                ]
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
                        },
                        {
                            "Names" : "Network",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
            },
            {
                "Names" : "Hibernate",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "StartUpMode",
                        "Type" : STRING_TYPE,
                        "Values" : ["replace"],
                        "Default" : "replace"
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
