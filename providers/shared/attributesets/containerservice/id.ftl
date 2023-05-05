[#ftl]

[@addAttributeSet
    type=CONTAINERSERVICE_ATTRIBUTESET_TYPE
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Describes the configuration required for a container service"
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
            "Names" : "Cpu",
            "Description" : "The Cpu available to all containers in the service - 0 will defer to the container allocations",
            "Types" : NUMBER_TYPE,
            "Default": 0
        },
        {
            "Names" : "Memory",
            "Description" : "The memory available to all containers in the service - 0 will defer to the container allocations",
            "Types" : NUMBER_TYPE,
            "Default": 0
        },
        {
            "Names" : "Containers",
            "SubObjects" : true,
            "AttributeSet" : CONTAINER_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "DesiredCount",
            "Types" : NUMBER_TYPE
        },
        {
            "Names" : "ScalingPolicies",
            "SubObjects" : true,
            "AttributeSet" : SCALINGPOLICY_ATTRIBUTESET_TYPE
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
            "Names" : "ContainerNetworkLinks",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "Placement",
            "Children" : [
                {
                    "Names" : "Strategy",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Values" : [
                        "spread-multiAZ",
                        "spread-instance",
                        "binpack-cpu",
                        "binpack-memory",
                        "daemon",
                        "random"
                    ],
                    "Description" : "How to place containers on the cluster",
                    "Default" : []
                },
                {
                    "Names" : "DistinctInstance",
                    "Types" : BOOLEAN_TYPE,
                    "Description" : "Each task is running on a different container instance when true",
                    "Default" : true
                },
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
                                },
                                {
                                    "Names" : "Weight",
                                    "Types" : NUMBER_TYPE,
                                    "Description" : "The ratio of containers allocated to the provider based on the configured providers",
                                    "Default" : 1
                                },
                                {
                                    "Names" : "RequiredCount",
                                    "Description" : "The minimum count of containers to run on the default provider",
                                    "Types" : NUMBER_TYPE,
                                    "Default" : 1
                                }
                            ]
                        },
                        {
                            "Names" : "Additional",
                            "Description" : "Providers who will meet the additional compute capacity outside of the default",
                            "SubObjects" : true,
                            "Children" : [
                                {
                                    "Names" : "Provider",
                                    "Types" : STRING_TYPE,
                                    "Values" : [ "_engine" ],
                                    "Mandatory" : true
                                },
                                {
                                    "Names" : "Weight",
                                    "Types" : NUMBER_TYPE,
                                    "Description" : "The ratio of containers allocated to the provider based on the configured providers",
                                    "Default" : 1
                                }
                            ]
                        }
                    ]
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
                        "Names" : "Processor",
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
