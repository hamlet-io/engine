[#ftl]

[#assign ECS_SERVICE_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        NAME_ATTRIBUTE_TYPE : {
            "Attribute" : "Name"
        }
    }
]

[#assign ECS_TASK_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]

[#assign ECS_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "Attribute" : "Arn"
        }
    }]

[#assign outputMappings +=
    {
        AWS_ECS_RESOURCE_TYPE : ECS_OUTPUT_MAPPINGS,
        AWS_ECS_SERVICE_RESOURCE_TYPE : ECS_SERVICE_OUTPUT_MAPPINGS,
        AWS_ECS_TASK_RESOURCE_TYPE : ECS_TASK_OUTPUT_MAPPINGS
    }
]

[#assign metricAttributes +=
    {
        AWS_ECS_RESOURCE_TYPE : {
            "Namespace" : "AWS/ECS",
            "Dimensions" : {
                "ClusterName" : {
                    "Output" : REFERENCE_ATTRIBUTE_TYPE
                }
            }
        },
        AWS_ECS_SERVICE_RESOURCE_TYPE : {
            "Namespace" : "AWS/ECS",
            "Dimensions" : {
                "ClusterName" : {
                    "OtherOutput" : {
                        "Id" : "cluster",
                        "Property" : ""
                    }
                },
                "ServiceName" : {
                    "Output" : NAME_ATTRIBUTE_TYPE
                }
            }
        }
    }
]

[#macro createECSCluster mode id ]
        [@cfResource
            mode=mode
            id=id
            type="AWS::ECS::Cluster"
            outputs=ECS_OUTPUT_MAPPINGS
        /]
[/#macro]

[#macro createECSTask mode id
    name
    containers
    engine
    executionRole
    networkMode=""
    fixedName=false
    role=""
    dependencies=""]

    [#local definitions = [] ]
    [#local volumes = [] ]

    [#local memoryTotal = 0]
    [#local cpuTotal = 0]
    [#list containers as container]
        [#local mountPoints = [] ]
        [#list (container.Volumes!{}) as name,volume]
            [#local mountPoints +=
                [
                    {
                        "ContainerPath" : volume.ContainerPath,
                        "SourceVolume" : name,
                        "ReadOnly" : volume.ReadOnly
                    }
                ]
            ]

            [#local dockerVolumeConfiguration = {} +
                volume.PersistVolume?then(
                    {
                        "Scope" : "shared",
                        "Autoprovision", volume.AutoProvision
                    },
                    {}
                ) +
                (volume.Driver != "local")?then(
                    {
                        "Driver" : volume.Driver
                    },
                    {}
                ) +
                (volume.DriverOpts?has_content)?then(
                    {
                        "DriverOpts" : volume.DriverOpts
                    },
                    {}
                )
            ]

            [#local volumes +=
                [
                    {
                        "Name" : name
                    } +
                    attributeIfTrue(
                        "Host",
                        volume.HostPath?has_content,
                        {"SourcePath" : volume.HostPath!""}) +
                    attributeIfTrue(
                        "DockerVolumeConfiguration",
                        dockerVolumeConfiguration?has_content,
                        dockerVolumeConfiguration
                    )
                ]
            ]
        [/#list]
        [#local portMappings = [] ]
        [#list (container.PortMappings![]) as portMapping]
            [#local portMappings +=
                [
                    {
                        "ContainerPort" : ports[portMapping.ContainerPort].Port,
                        "HostPort" : portMapping.DynamicHostPort?then(0, ports[portMapping.HostPort].Port)
                    }
                ]
            ]
        [/#list]
        [#local environment = [] ]
        [#list (container.Environment!{}) as name,value]
            [#local environment +=
                [
                    {
                        "Name" : name,
                        "Value" : value
                    }
                ]
            ]
        [/#list]
        [#local extraHosts = [] ]
        [#list (container.Hosts!{}) as name,value]
            [#local extraHosts +=
                [
                    {
                        "Hostname" : name,
                        "IpAddress" : value
                    }
                ]
            ]
        [/#list]
        [#if engine == "fargate" ]
            [#local memoryTotal += container.MaximumMemory]
            [#local cpuTotal += container.Cpu]
        [/#if]
        [#local definitions +=
            [
                {
                    "Name" : container.Name,
                    "Image" :
                        formatRelativePath(
                            container.RegistryEndPoint,
                            container.Image +
                                container.ImageVersion?has_content?then(
                                    ":" + container.ImageVersion,
                                    ""
                                )
                            ),
                    "Essential" : container.Essential,
                    "MemoryReservation" : container.MemoryReservation,
                    "LogConfiguration" :
                        {
                            "LogDriver" : container.LogDriver
                        } +
                        attributeIfContent("Options", container.LogOptions)
                } +
                attributeIfContent("Environment", environment) +
                attributeIfContent("MountPoints", mountPoints) +
                attributeIfContent("ExtraHosts", extraHosts) +
                attributeIfContent("Memory", container.MaximumMemory!"") +
                attributeIfContent("Cpu", container.Cpu!"") +
                attributeIfContent("PortMappings", portMappings) +
                attributeIfContent("LinuxParameters", container.RunCapabilities![],
                                        {
                                            "Capabilities" : {
                                                "Add" : container.RunCapabilities![]
                                            }
                                        }
                                    ) +
                attributeIfTrue("Privileged", container.Privileged, container.Privileged!"") +
                attributeIfContent("WorkingDirectory", container.WorkingDirectory!"") +
                attributeIfContent("Links", container.ContainerNetworkLinks![] ) +
                attributeIfContent("EntryPoint", container.EntryPoint![]) +
                attributeIfContent("Command", container.Command![])
            ]
        ]
    [/#list]

    [#local taskProperties = {
        "ContainerDefinitions" : definitions
        } +
        attributeIfContent("Volumes", volumes)  +
        attributeIfContent("TaskRoleArn", role, getReference(role, ARN_ATTRIBUTE_TYPE)) +
        attributeIfContent("NetworkMode", networkMode) +
        attributeIfTrue("Family", fixedName, name ) +
        attributeIfContent("ExecutionRoleArn", executionRole, getReference(executionRole, ARN_ATTRIBUTE_TYPE)) +
        valueIfTrue(
            {
                "RequiresCompatibilities" : [ engine?upper_case ],
                "Cpu" : cpuTotal,
                "Memory" : memoryTotal
            },
            (engine == "fargate")
        )
    ]

    [@cfResource
        mode=mode
        id=id
        type="AWS::ECS::TaskDefinition"
        properties=taskProperties
        dependencies=dependencies
        outputs=ECS_TASK_OUTPUT_MAPPINGS
    /]
[/#macro]

[#macro createECSService mode id
            ecsId
            desiredCount
            taskId
            loadBalancers
            serviceRegistries
            engine
            networkMode=""
            networkConfiguration={}
            roleId=""
            placement={}
            dependencies=""
    ]

    [@cfResource
        mode=mode
        id=id
        type="AWS::ECS::Service"
        properties=
            {
                "Cluster" : getExistingReference(ecsId),
                "TaskDefinition" : getReference(taskId),
                "DeploymentConfiguration" :
                    (desiredCount > 1)?then(
                        {
                            "MaximumPercent" : 100,
                            "MinimumHealthyPercent" : 50
                        },
                        {
                            "MaximumPercent" : 100,
                            "MinimumHealthyPercent" : 0
                        })
            } +
            valueIfContent(
                {
                    "LoadBalancers" : loadBalancers
                },
                loadBalancers) +
            valueIfContent(
                {
                    "ServiceRegistries" : serviceRegistries
                },
                serviceRegistries) +
            valueIfTrue(
                {
                    "SchedulingStrategy" : "DAEMON"
                },
                (placement.Strategy == "daemon" && engine == "ec2" ),
                {
                    "DesiredCount" : desiredCount
                }
            ) +
            valueIfTrue(
                {
                    "Role" : getReference(roleId)
                },
                (loadBalancers![])?has_content && networkMode != "awsvpc"
            ) +
            attributeIfTrue(
                "LaunchType",
                engine == "fargate",
                engine?upper_case
            ) +
            attributeIfContent(
                "NetworkConfiguration",
                networkConfiguration
            )
        dependencies=dependencies
        outputs=ECS_SERVICE_OUTPUT_MAPPINGS
    /]
[/#macro]

