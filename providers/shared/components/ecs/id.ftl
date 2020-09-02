[#ftl]

[#assign
    containerChildrenConfiguration = [
        {
            "Names" : "Cpu",
            "Type" : NUMBER_TYPE,
            "Default" : ""
        },
        {
            "Names" : "Links",
            "Subobjects" : true,
            "Children" : linkChildrenConfiguration
        },
        {
            "Names" : "LocalLogging",
            "Type" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "LogDriver",
            "Type" : STRING_TYPE,
            "Values" : ["awslogs", "json-file", "fluentd"],
            "Default" : "awslogs"
        },
        {
            "Names" : "LogMetrics",
            "Subobjects" : true,
            "Children" : logMetricChildrenConfiguration
        },
        {
            "Names" : "Alerts",
            "Subobjects" : true,
            "Children" : alertChildrenConfiguration
        },
        {
            "Names" : "ContainerLogGroup",
            "Type" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "RunCapabilities",
            "Type" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "Privileged",
            "Type" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : ["MaximumMemory", "MemoryMaximum", "MaxMemory"],
            "Types" : NUMBER_TYPE,
            "Description" : "Set to 0 to not set a maximum"
        },
        {
            "Names" : ["MemoryReservation", "Memory", "ReservedMemory"],
            "Type" : NUMBER_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Ports",
            "Subobjects" : true,
            "Children" : [
                "Container",
                {
                    "Names" : "DynamicHostPort",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "LB",
                    "Children" : lbChildConfiguration
                },
                {
                    "Names" : "Registry",
                    "Children" : srvRegChildConfiguration
                },
                {
                    "Names" : "IPAddressGroups",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        },
        {
            "Names" : "Version",
            "Type" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "ContainerNetworkLinks",
            "Type" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        }
        {
            "Names" : "Profiles",
            "Children" :
                [
                    {
                        "Names" : "Alert",
                        "Type" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
        },
        {
            "Names" : "RunMode",
            "Description" : "A per container setting which can be used by the app to determine run mode for a container in a task - defaults to the second half of a dash separated id",
            "Type" : STRING_TYPE,
            "Default" : ""
        }
    ]
]

[@addComponentDeployment
    type=ECS_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addComponent
    type=ECS_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "An autoscaling container host cluster"
            }
        ]
    attributes=
        [
            {
                "Names" : ["Fragment", "Container"],
                "Type" : "string",
                "Default" : ""
            },
            {
                "Names" : "FixedIP",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "LogDriver",
                "Type" : STRING_TYPE,
                "Values" : ["awslogs", "json-file", "fluentd"],
                "Default" : "awslogs"
            },
            {
                "Names" : "VolumeDrivers",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Values" : [ "ebs" ],
                "Default" : []
            },
            {
                "Names" : "ClusterLogGroup",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
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
                        },
                        {
                            "Names" : "Network",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Logging",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
            },
            {
                "Names" : "AutoScaling",
                "Children" : autoScalingChildConfiguration
            },
            {
                "Names" : "HostScalingPolicies",
                "Subobjects" : true,
                "Children" : scalingPolicyChildrenConfiguration
            },
            {
                "Names" : "DockerUsers",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "UserName",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "UID",
                        "Type" : NUMBER_TYPE,
                        "Mandatory" : true
                    }
                ]
            },
            {
                "Names" : "LogMetrics",
                "Subobjects" : true,
                "Children" : logMetricChildrenConfiguration
            },
            {
                "Names" : "Alerts",
                "Subobjects" : true,
                "Children" : alertChildrenConfiguration
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
                "Names" : "Role",
                "Description" : "Server configuration role",
                "Default" : ""
            },
            {
                "Names" : "ComputeProvider",
                "Description" : "The default compute provider for the cluster",
                "Values" : [ "ec2", "ec2OnDemand" ],
                "Default" : "ec2"
            }
        ]
/]

[@addComponentDeployment
    type=ECS_SERVICE_COMPONENT_TYPE
    defaultGroup="application"
/]

[@addChildComponent
    type=ECS_SERVICE_COMPONENT_TYPE
    parent=ECS_COMPONENT_TYPE
    childAttribute="Services"
    linkAttributes="Service"
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "An orchestrated container with always on scheduling"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Type" : STRING_TYPE,
                "Values" : [ "ec2", "fargate" ],
                "Default" : "ec2"
            },
            {
                "Names" : "Containers",
                "Subobjects" : true,
                "Children" : containerChildrenConfiguration
            },
            {
                "Names" : "DesiredCount",
                "Type" : NUMBER_TYPE
            },
            {
                "Names" : "ScalingPolicies",
                "Subobjects" : true,
                "Children" : scalingPolicyChildrenConfiguration
            },
            {
                "Names" : "UseTaskRole",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Permissions",
                "Children" : [
                    {
                        "Names" : "Decrypt",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AsFile",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AppData",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AppPublic",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "TaskLogGroup",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "LogMetrics",
                "Subobjects" : true,
                "Children" : logMetricChildrenConfiguration
            },
            {
                "Names" : "Alerts",
                "Subobjects" : true,
                "Children" : alertChildrenConfiguration
            },
            {
                "Names" : "NetworkMode",
                "Type" : STRING_TYPE,
                "Values" : ["none", "bridge", "awsvpc", "host"],
                "Default" : ""
            },
            {
                "Names" : "ContainerNetworkLinks",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Placement",
                "Children" : [
                    {
                        "Names" : "Strategy",
                        "Type" : STRING_TYPE,
                        "Values" : [ "", "daemon"],
                        "Description" : "How to place containers on the cluster",
                        "Default" : ""
                    },
                    {
                        "Names" : "DistinctInstance",
                        "Type" : BOOLEAN_TYPE,
                        "Description" : "Each task is running on a different container instance when true",
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "Profiles",
                "Children" :
                    [
                        {
                            "Names" : "Alert",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Processor",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Network",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Logging",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
/]

[@addComponentDeployment
    type=ECS_TASK_COMPONENT_TYPE
    defaultGroup="application"
/]

[@addChildComponent
    type=ECS_TASK_COMPONENT_TYPE
    parent=ECS_COMPONENT_TYPE
    childAttribute="Tasks"
    linkAttributes="Task"
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A container defintion which is invoked on demand"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Type" : STRING_TYPE,
                "Values" : [ "ec2", "fargate" ],
                "Default" : "ec2"
            },
            {
                "Names" : "Containers",
                "Subobjects" : true,
                "Children" : containerChildrenConfiguration
            },
            {
                "Names" : "UseTaskRole",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Permissions",
                "Children" : [
                    {
                        "Names" : "Decrypt",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AsFile",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AppData",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AppPublic",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "TaskLogGroup",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "LogMetrics",
                "Subobjects" : true,
                "Children" : logMetricChildrenConfiguration
            },
            {
                "Names" : "Alerts",
                "Subobjects" : true,
                "Children" : alertChildrenConfiguration
            },
            {
                "Names" : "NetworkMode",
                "Type" : STRING_TYPE,
                "Values" : ["none", "bridge", "awsvpc", "host"],
                "Default" : ""
            },
            {
                "Names" : "FixedName",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Schedules",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "Expression",
                        "Type" : STRING_TYPE,
                        "Default" : "rate(1 hours)"
                    },
                    {
                        "Names" : "TaskCount",
                        "Description" : "The number of tasks to run on the schedule",
                        "Type" : NUMBER_TYPE,
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
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Network",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Logging",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
/]
