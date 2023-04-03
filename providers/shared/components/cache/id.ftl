[#ftl]

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
                "Description" : "The type of cache engine to use",
                "Types" : STRING_TYPE,
                "Values" : [ "memcached", "redis" ],
                "Mandatory" : true
            },
            {
                "Names" : "EngineVersion",
                "Description" : "The version of the engine type",
                "Types" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "Port",
                "Description" : "The network port the cache listens on - defaults to a port with the same name as the engine",
                "Types" : STRING_TYPE
            },
            {
                "Names" : [ "MultiAZ", "MultiZone"],
                "Description" : "Deploy resources to multiple Availablity Zones",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "IPAddressGroups",
                "Description" : "The source ip addresses that can access the cache",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "_localnet" ]
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Backup",
                "Children" : [
                    {
                        "Names" : "RetentionPeriod",
                        "Description" : "How many days to keep snapshots for - 0 disabled snapshots",
                        "Types" : NUMBER_TYPE,
                        "Default" : 0
                    }
                ]
            },
            {
                "Names" : "MaintenanceWindow",
                "AttributeSet" : MAINTENANCEWINDOW_ATTRIBUTESET_TYPE
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
                            "Names" : "Alert",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Network",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
            },
            {
                "Names" : "Hibernate",
                "Description" : "Remove any services which charge by the hour",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "StartUpMode",
                        "Types" : STRING_TYPE,
                        "Values" : ["replace"],
                        "Default" : "replace"
                    }
                ]
            },
            {
                "Names" : "Alerts",
                "SubObjects" : true,
                "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
            }
        ]
/]

[@addComponentDeployment
    type=CACHE_COMPONENT_TYPE
    defaultGroup="solution"
/]
