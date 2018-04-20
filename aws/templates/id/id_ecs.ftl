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
            "Default" : ""
        },
        {
            "Name" : "Links",
            "Subobjects" : true,
            "Children" : linkChildrenConfiguration
        },
        {
            "Name" : "LocalLogging",
            "Default" : false
        },
        {
            "Name" : "LogDriver",
            "Default" : "awslogs"
        },
        {
            "Name" : "ContainerLogGroup",
            "Default" : false
        },
        {
            "Name" : ["MaximumMemory", "MemoryMaximum", "MaxMemory"]
        },
        {
            "Name" : ["MemoryReservation", "Memory", "ReservedMemory"],
            "Mandatory" : true
        },
        {
            "Name" : "Ports",
            "Subobjects" : true,
            "Children" : [
                "Container",
                {
                    "Name" : "DynamicHostPort",
                    "Default" : false
                },
                {
                    "Name" : "ELB",
                    "Default" : ""
                },
                {
                    "Name" : "LB",
                    "Children" : lbChildConfiguration
                }
            ]
        },
        {
            "Name" : "Version",
            "Default" : ""
        }
    ]
]

[#assign componentConfiguration +=
    {
        ECS_COMPONENT_TYPE : {
            "Attributes" : [
                {
                    "Name" : "ClusterWideStorage",
                    "Default" : false
                },
                {
                    "Name" : "FixedIP",
                    "Default" : false
                },
                {
                    "Name" : "LogDriver",
                    "Default" : "awslogs"
                },
                {
                    "Name" : "ClusterLogGroup",
                    "Default" : true,
                },
                {
                    "Name" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
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
                "Default" : -1
            },
            {
                "Name" : "UseTaskRole",
                "Default" : true
            },
            {
                "Name" : "Permissions",
                "Children" : [
                    {
                        "Name" : "Decrypt",
                        "Default" : true
                    },
                    {
                        "Name" : "AsFile",
                        "Default" : true
                    },
                    {
                        "Name" : "AppData",
                        "Default" : true
                    },
                    {
                        "Name" : "AppPublic",
                        "Default" : true
                    }
                ]
            },
            {
                "Name" : "TaskLogGroup",
                "Default" : true
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
                "Default" : true
            },
            {
                "Name" : "Permissions",
                "Children" : [
                    {
                        "Name" : "Decrypt",
                        "Default" : true
                    },
                    {
                        "Name" : "AsFile",
                        "Default" : true
                    },
                    {
                        "Name" : "AppData",
                        "Default" : true
                    },
                    {
                        "Name" : "AppPublic",
                        "Default" : true
                    }
                ]
            },
            {
                "Name" : "TaskLogGroup",
                "Default" : true
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
                }
            } +
            attributeIfTrue(
                "lg",
                solution.ClusterLogGroup,
                {
                    "Id" : formatLogGroupId(core.Id),
                    "Name" : core.FullAbsolutePath,
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                }
            ),
            "Attributes" : {},
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

    [#return
        {
            "Resources" : {
                "service" : {
                    "Id" : formatResourceId(AWS_ECS_SERVICE_RESOURCE_TYPE, core.Id),
                    "Type" : AWS_ECS_SERVICE_RESOURCE_TYPE
                },
                "task" : {
                    "Id" : taskId,
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
            ),
            "Attributes" : {},
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]

[#function getTaskState occurrence]
    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]

    [#local taskId = formatResourceId(AWS_ECS_TASK_RESOURCE_TYPE, core.Id) ]

    [#return
        {
            "Resources" : {
                "task" : {
                    "Id" : taskId,
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
            ),
            "Attributes" : {},
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]

[#-- Container --]

[#function formatContainerFragmentId occurrence container]
    [#return formatName(
                getContainerId(container),
                occurrence.Core.Instance.Id,
                occurrence.Core.Version.Id)]
[/#function]

[#function formatContainerSecurityGroupIngressId resourceId container portRange]
    [#return formatDependentSecurityGroupIngressId(
                resourceId,
                getContainerId(container),
                portRange)]
[/#function]
