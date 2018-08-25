[#-- ECS --]

[#-- Resources --]
[#assign AWS_ECS_RESOURCE_TYPE = "ecs" ]
[#assign AWS_ECS_TASK_RESOURCE_TYPE = "ecsTask"]
[#assign AWS_ECS_SERVICE_RESOURCE_TYPE = "ecsService"]

[#-- Components --]
[#assign ECS_COMPONENT_TYPE = "ecs" ]
[#assign ECS_SERVICE_COMPONENT_TYPE = "service" ]
[#assign ECS_TASK_COMPONENT_TYPE = "task" ]

[#assign
    containerChildrenConfiguration = [
        {
            "Name" : "Cpu",
            "Type" : "number",
            "Default" : ""
        },
        {
            "Name" : "Links",
            "Subobjects" : true,
            "Children" : linkChildrenConfiguration
        },
        {
            "Name" : "LocalLogging",
            "Type" : "boolean",
            "Default" : false
        },
        {
            "Name" : "LogDriver",
            "Type" : "string",
            "Values" : ["awslogs", "json-file", "fluentd"],
            "Default" : "awslogs"
        },
        {
            "Name" : "ContainerLogGroup",
            "Type" : "boolean",
            "Default" : false
        },
        {
            "Name" : "RunCapabilities",
            "Type" : "array",
            "Default" : []
        },
        {
            "Name" : "Privileged",
            "Type" : "boolean",
            "Default" : false
        },
        {
            "Name" : ["MaximumMemory", "MemoryMaximum", "MaxMemory"],
            "Types" : "number",
            "Description" : "Set to 0 to not set a maximum"
        },
        {
            "Name" : ["MemoryReservation", "Memory", "ReservedMemory"],
            "Type" : "number",
            "Mandatory" : true
        },
        {
            "Name" : "Ports",
            "Subobjects" : true,
            "Children" : [
                "Container",
                {
                    "Name" : "DynamicHostPort",
                    "Type" : "boolean",
                    "Default" : false
                }
                {
                    "Name" : "LB",
                    "Children" : lbChildConfiguration
                },
                {
                    "Name" : "IPAddressGroups",
                    "Type" : "array",
                    "Default" : []
                }
            ]
        },
        {
            "Name" : "Version",
            "Type" : "string",
            "Default" : ""
        },
        {
            "Name" : "ContainerNetworkLinks",
            "Type" : "array",
            "Default" : []
        }
    ]
]

[#assign componentConfiguration +=
    {
        ECS_COMPONENT_TYPE : {
            "Attributes" : [
                {
                    "Name" : "FixedIP",
                    "Type" : "boolean",
                    "Default" : false
                },
                {
                    "Name" : "LogDriver",
                    "Type" : "string",
                    "Values" : ["awslogs", "json-file", "fluentd"],
                    "Default" : "awslogs"
                },
                {
                    "Name" : "ClusterLogGroup",
                    "Type" : "boolean",
                    "Default" : true
                },
                {
                    "Name" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Name" : "DockerUsers",
                    "Subobjects" : true,
                    "Children" : [
                        {
                            "Name" : "UserName",
                            "Type" : "string"
                        },
                        {
                            "Name" : "UID",
                            "Type" : "string",
                            "Mandatory" : true
                        }
                    ]
                }
            ],
            "Components" : [
                {
                    "Type" : ECS_SERVICE_COMPONENT_TYPE,
                    "Component" : "Services",
                    "Link" : "Service"
                },
                {
                    "Type" : ECS_TASK_COMPONENT_TYPE,
                    "Component" : "Tasks",
                    "Link" : "Task"
                }
            ]
        },
        ECS_SERVICE_COMPONENT_TYPE : [
            {
                "Name" : "Containers",
                "Subobjects" : true,
                "Children" : containerChildrenConfiguration
            },
            {
                "Name" : "DesiredCount",
                "Type" : "number",
                "Default" : -1
            },
            {
                "Name" : "UseTaskRole",
                "Type" : "boolean",
                "Default" : true
            },
            {
                "Name" : "Permissions",
                "Children" : [
                    {
                        "Name" : "Decrypt",
                        "Type" : "boolean",
                        "Default" : true
                    },
                    {
                        "Name" : "AsFile",
                        "Type" : "boolean",
                        "Default" : true
                    },
                    {
                        "Name" : "AppData",
                        "Type" : "boolean",
                        "Default" : true
                    },
                    {
                        "Name" : "AppPublic",
                        "Type" : "boolean",
                        "Default" : true
                    }
                ]
            },
            {
                "Name" : "TaskLogGroup",
                "Type" : "boolean",
                "Default" : true
            },
            {
                "Name" : "NetworkMode",
                "Type" : "string",
                "Values" : ["none", "bridge", "awsvpc", "host"],
                "Default" : ""
            },
            {
                "Name" : "ContainerNetworkLinks",
                "Type" : "boolean",
                "Default" : false
            }
        ],
        ECS_TASK_COMPONENT_TYPE : [
            {
                "Name" : "Containers",
                "Subobjects" : true,
                "Children" : containerChildrenConfiguration
            },
            {
                "Name" : "UseTaskRole",
                "Type" : "boolean",
                "Default" : true
            },
            {
                "Name" : "Permissions",
                "Children" : [
                    {
                        "Name" : "Decrypt",
                        "Type" : "boolean",
                        "Default" : true
                    },
                    {
                        "Name" : "AsFile",
                        "Type" : "boolean",
                        "Default" : true
                    },
                    {
                        "Name" : "AppData",
                        "Type" : "boolean",
                        "Default" : true
                    },
                    {
                        "Name" : "AppPublic",
                        "Type" : "boolean",
                        "Default" : true
                    }
                ]
            },
            {
                "Name" : "TaskLogGroup",
                "Type" : "boolean",
                "Default" : true
            },
            {
                "Name" : "FixedName",
                "Type" : "boolean",
                "Default" : false
            }
        ]
    } ]


[#function getECSState occurrence]
    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]

    [#-- TODO(mfl): Use formatDependentRoleId() for roles --]
    [#return
        {
            "Resources" : {
                "cluster" : {
                    "Id" : formatResourceId(AWS_ECS_RESOURCE_TYPE, core.Id),
                    "Name" : core.FullName,
                    "Type" : AWS_ECS_RESOURCE_TYPE
                },
                "securityGroup" : {
                    "Id" : formatComponentSecurityGroupId(core.Tier, core.Component),
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                },
                "role" : {
                    "Id" : formatComponentRoleId(core.Tier, core.Component),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                },
                "serviceRole" : {
                    "Id" : formatComponentRoleId(core.Tier, core.Component, "service"),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                },
                "instanceProfile" : {
                    "Id" : formatEC2InstanceProfileId(core.Tier, core.Component),
                    "Type" : AWS_EC2_INSTANCE_PROFILE_RESOURCE_TYPE
                },
                "autoScaleGroup" : {
                    "Id" : formatEC2AutoScaleGroupId(core.Tier, core.Component),
                    "Type" : AWS_EC2_AUTO_SCALE_GROUP_RESOURCE_TYPE
                },
                "launchConfig" : {
                    "Id" : formatEC2LaunchConfigId(core.Tier, core.Component),
                    "Type" : AWS_EC2_LAUNCH_CONFIG_RESOURCE_TYPE
                },
                "lg" : {
                    "Id" : formatLogGroupId(core.Id),
                    "Name" : core.FullAbsolutePath,
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                },
                "lgInstanceLog" : {
                    "Id" : formatLogGroupId(core.Id, "instancelog"),
                    "Name" : formatAbsolutePath( core.FullAbsolutePath, "instancelog"),
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                }
            },
            "Attributes" : {
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]

[#function getServiceState occurrence]
    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]

    [#local taskId = formatResourceId(AWS_ECS_TASK_RESOURCE_TYPE, core.Id) ]
    [#local taskName = core.Name]

    [#return
        {
            "Resources" : {
                "service" : {
                    "Id" : formatResourceId(AWS_ECS_SERVICE_RESOURCE_TYPE, core.Id),
                    "Type" : AWS_ECS_SERVICE_RESOURCE_TYPE
                },
                "task" : {
                    "Id" : taskId,
                    "Name" : taskName,
                    "Type" : AWS_ECS_TASK_RESOURCE_TYPE
                }
            } +
            attributeIfTrue(
                "lg",
                solution.TaskLogGroup,
                {
                    "Id" : formatDependentLogGroupId(taskId),
                    "Name" : core.FullAbsolutePath,
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                }
            ) +
            attributeIfTrue(
                "taskrole"
                solution.UseTaskRole,
                {
                    "Id" : formatDependentRoleId(taskId),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                }    
            ) + 
            attributeIfTrue(
                "securityGroup",
                solution.NetworkMode == "awsvpc",
                {
                    "Id" : formatResourceId( AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE, core.Id ),
                    "Name" : core.FullName,
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                }),
            "Attributes" : {
                "Name" : core.Name
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]

[#function getTaskState occurrence parent]
    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]

    [#local parentResources = parent.State.Resources ]
    [#local ecsId = parentResources["cluster"].Id ]

    [#local taskId = formatResourceId(AWS_ECS_TASK_RESOURCE_TYPE, core.Id) ]
    [#local taskName = core.Name]
    [#local taskRoleId = formatDependentRoleId(taskId)]

    [#return
        {
            "Resources" : {
                "task" : {
                    "Id" : taskId,
                    "Name" : taskName,
                    "Type" : AWS_ECS_TASK_RESOURCE_TYPE
                }
            } +
            attributeIfTrue(
                "lg",
                solution.TaskLogGroup,
                {
                    "Id" : formatDependentLogGroupId(taskId),
                    "Name" : core.FullAbsolutePath,
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                }
            ) +
            attributeIfTrue(
                "taskrole"
                solution.UseTaskRole,
                {
                    "Id" : taskRoleId,
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                }    
            ),
            "Attributes" : {
                "ECSHOST" : getExistingReference(ecsId)
            } + 
                attributeIfTrue(
                    "DEFINITION",
                    solution.FixedName,
                    taskName
                ),
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {
                    "run" :  ecsTaskRunPermission(ecsId) +
                        solution.UseTaskRole?then(
                            iamPassRolePermission(
                                getExistingReference(taskRoleId, ARN_ATTRIBUTE_TYPE)
                            ),
                            []
                        ) 
                } 
            }
        }
    ]
[/#function]

[#function formatEcsClusterArn ecsId account={ "Ref" : "AWS::AccountId" }]
    [#return
        formatRegionalArn(
            "ecs",
            formatRelativePath(
                "cluster",
                getReference(ecsId)
            )
        )
    ]
[/#function]

[#-- Container --]

[#function formatContainerSecurityGroupIngressId resourceId container portRange source=""]
    [#return formatDependentSecurityGroupIngressId(
                resourceId,
                getContainerId(container),
                portRange,
                source)]
[/#function]
