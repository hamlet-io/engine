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
                }
                {
                    "Names" : "LB",
                    "Children" : lbChildConfiguration
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
    ]
]

[#assign componentConfiguration +=
    {
        ECS_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "An autoscaling container host cluster"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                }
            ],
            "Attributes" : [
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
                    "Children" : profileChildConfiguration
                },
                {
                    "Names" : "AutoScaling",
                    "Children" : autoScalingChildConfiguration
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
        ECS_SERVICE_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "An orchestrated container with always on scheduling"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "application"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Containers",
                    "Subobjects" : true,
                    "Children" : containerChildrenConfiguration
                },
                {
                    "Names" : "DesiredCount",
                    "Type" : NUMBER_TYPE,
                    "Default" : -1
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
                        }
                    ]
                },
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration
                }
            ]
        },
        ECS_TASK_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "A container defintion which is invoked on demand"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "application"
                }
            ],
            "Attributes" : [
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
                    "Names" : "FixedName",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration
                }
            ]
        }
    } ]


[#function getECSState occurrence]
    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]

    [#local logMetrics = {} ]
    [#list solution.LogMetrics as name,logMetric ]
        [#local logMetrics += {
            "lgMetric" + name : {
                "Id" : formatLogMetricId( core.Id, logMetric.Id ),
                "Name" : getMetricName( logMetric.Name, AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE, occurrence ),
                "Type" : AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE
            }
        }]
    [/#list]

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
                    "Id" : solution.AutoScaling.AlwaysReplaceOnUpdate?then(
                            formatEC2LaunchConfigId(core.Tier, core.Component, runId),
                            formatEC2LaunchConfigId(core.Tier, core.Component)
                    ),
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
            } + 
            logMetrics,
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

    [#local logMetrics = {} ]
    [#list solution.LogMetrics as name,logMetric ]
        [#local logMetrics += {
            "lgMetric" + name : {
                "Id" : formatLogMetricId( core.Id, logMetric.Id ),
                "Name" : getMetricName( logMetric.Name, AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE, occurrence ),
                "Type" : AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE
            }
        }]
    [/#list]

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
            logMetrics +
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

    [#local logMetrics = {} ]
    [#list solution.LogMetrics as name,logMetric ]
        [#local logMetrics += {
            "lgMetric" + name : {
                "Id" : formatLogMetricId( core.Id, logMetric.Id ),
                "Name" : getMetricName( logMetric.Name, AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE, occurrence ),
                "Type" : AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE
            }
        }]
    [/#list]

    [#return
        {
            "Resources" : {
                "task" : {
                    "Id" : taskId,
                    "Name" : taskName,
                    "Type" : AWS_ECS_TASK_RESOURCE_TYPE
                }
            } +
            logMetrics +
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
