[#ftl]

[@addAttributeSet
    type=CONTAINERTASK_ATTRIBUTESET_TYPE
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Describes the configuration required for a container task"
        }
    ]
    attributes=[
        {
            "Names" : "Engine",
            "Description" : "The engine used to run the container",
            "Types" : STRING_TYPE,
            "Values" : [ "ec2" ],
            "Default" : "ec2"
        },
        {
            "Names" : [ "MultiAZ", "MultiZone"],
            "Description" : "Deploy resources to multiple Availablity Zones",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "Containers",
            "SubObjects" : true,
            "AttributeSet" : CONTAINER_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "UseTaskRole",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "Permissions",
            "Children" : [
                {
                    "Names" : "Decrypt",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "AsFile",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "AppData",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                }
            ]
        },
        {
            "Names" : "Placement",
            "Children" : [
                {
                    "Names" : "ComputeProvider",
                    "Description" : "The compute provider placement policy",
                    "Children" : [
                        {
                            "Names" : "Default",
                            "Children" : [
                                {
                                    "Names" : "Provider",
                                    "Description" : "The default container compute provider - _engine uses the default provider of the engine",
                                    "Types"  : STRING_TYPE,
                                    "Values" : [ "_engine" ],
                                    "Default" : "_engine"
                                }
                            ]
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "TaskLogGroup",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "LogMetrics",
            "SubObjects" : true,
            "AttributeSet" : LOGMETRIC_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "Alerts",
            "SubObjects" : true,
            "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "NetworkMode",
            "Types" : STRING_TYPE,
            "Values" : ["none", "bridge", "host"],
            "Default" : ""
        },
        {
            "Names" : "FixedName",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "Schedules",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Expression",
                    "Types" : STRING_TYPE,
                    "Default" : "rate(1 hours)"
                },
                {
                    "Names" : "TaskCount",
                    "Description" : "The number of tasks to run on the schedule",
                    "Types" : NUMBER_TYPE,
                    "Default" : 1
                }
            ]
        },
        {
            "Names" : "Profiles",
            "Children" :
                [
                    {
                        "Names" : "Alert",
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
            "Names" : "Links",
            "SubObjects": true,
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
        }
    ]
/]
