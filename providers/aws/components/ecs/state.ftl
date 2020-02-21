[#ftl]

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

[#macro aws_ecs_cf_state occurrence parent={} ]
    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]

    [#local clusterId = formatResourceId(AWS_ECS_RESOURCE_TYPE, core.Id)]

    [#local lgId = formatLogGroupId(core.Id) ]
    [#local lgName = core.FullAbsolutePath ]

    [#local autoScaleGroupId = formatEC2AutoScaleGroupId(core.Tier, core.Component)]

    [#local lgInstanceLogId = formatLogGroupId(core.Id, "instancelog") ]
    [#local lgInstanceLogName = formatAbsolutePath( core.FullAbsolutePath, "instancelog") ]

    [#local logMetrics = {} ]
    [#list solution.LogMetrics as name,logMetric ]
        [#local logMetrics += {
            "lgMetric" + name : {
                "Id" : formatDependentLogMetricId( lgId, logMetric.Id ),
                "Name" : getMetricName( logMetric.Name, AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE, core.ShortFullName ),
                "Type" : AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE,
                "LogGroupName" : lgName,
                "LogGroupId" : lgId,
                "LogFilter" : logMetric.LogFilter
            },
            "lgMetric" + name + "instancelog": {
                "Id" : formatDependentLogMetricId( lgInstanceLogId, logMetric.Id ),
                "Name" : formatName(getMetricName( logMetric.Name, AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE, core.ShortFullName ),  "instancelog"),
                "Type" : AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE,
                "LogGroupName" : lgInstanceLogName,
                "LogGroupId" : lgInstanceLogId,
                "LogFilter" : logMetric.LogFilter
            }
        }]
    [/#list]

    [#local autoScaling = {}]
    [#if solution.HostScalingPolicies?has_content ]
        [#list solution.HostScalingPolicies as name, scalingPolicy ]

            [#if scalingPolicy.Type == "scheduled" ]
                [#local autoScaling +=
                    {
                        "scalingPolicy" + name : {
                            "Id" : formatDependentAutoScalingEc2ScheduleId(autoScaleGroupId, name),
                            "Name" : formatName(core.FullName, name),
                            "Type" : AWS_AUTOSCALING_EC2_SCHEDULE_RESOURCE_TYPE
                        }
                    }
                ]
            [#else]
                [#local autoScaling +=
                    {
                        "scalingPolicy" + name : {
                            "Id" : formatDependentAutoScalingEc2PolicyId(autoScaleGroupId, name),
                            "Name" : formatName(core.FullName, name),
                            "Type" : AWS_AUTOSCALING_EC2_POLICY_RESOURCE_TYPE
                        }
                    }
                ]
            [/#if]
        [/#list]
    [/#if]

    [#local computeProvider = {}]
    [#if solution.ComputeProvider == "ec2OnDemand" ]
        [#local computeProvider += {
                "ecsCapacityProviderOnDemand" : {
                    "Id" : formatResourceId(AWS_ECS_CAPACIITY_PROVIDER_RESOURCE_TYPE, core.Id, 'OnDemand'),
                    "Type" : AWS_ECS_CAPACIITY_PROVIDER_RESOURCE_TYPE
                }
            }
        ]
    [/#if]

    [#-- TODO(mfl): Use formatDependentRoleId() for roles --]
    [#assign componentState =
        {
            "Resources" : {
                "cluster" : {
                    "Id" : clusterId,
                    "Name" : core.FullName,
                    "Type" : AWS_ECS_RESOURCE_TYPE,
                    "Monitored" : true
                },
                "securityGroup" : {
                    "Id" : formatComponentSecurityGroupId(core.Tier, core.Component),
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                },
                "role" : {
                    "Id" : formatComponentRoleId(core.Tier, core.Component),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
                },
                "instanceProfile" : {
                    "Id" : formatEC2InstanceProfileId(core.Tier, core.Component),
                    "Type" : AWS_EC2_INSTANCE_PROFILE_RESOURCE_TYPE
                },
                "autoScaleGroup" : {
                    "Id" : autoScaleGroupId,
                    "Type" : AWS_EC2_AUTO_SCALE_GROUP_RESOURCE_TYPE
                },
                "launchConfig" : {
                    "Id" : solution.AutoScaling.AlwaysReplaceOnUpdate?then(
                            formatEC2LaunchConfigId(core.Tier, core.Component, commandLineOptions.Run.Id),
                            formatEC2LaunchConfigId(core.Tier, core.Component)
                    ),
                    "Type" : AWS_EC2_LAUNCH_CONFIG_RESOURCE_TYPE
                },
                "lg" : {
                    "Id" : lgId,
                    "Name" : lgName,
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
                },
                "lgInstanceLog" : {
                    "Id" : lgInstanceLogId,
                    "Name" : lgInstanceLogName,
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
                }
            } +
            attributeIfContent("logMetrics", logMetrics) +
            autoScaling +
            computeProvider,
            "Attributes" : {
                "ARN" : getExistingReference(clusterId, ARN_ATTRIBUTE_TYPE)
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]

[#macro aws_service_cf_state occurrence parent={} ]
    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]

    [#local serviceId = formatResourceId(AWS_ECS_SERVICE_RESOURCE_TYPE, core.Id)]
    [#local taskId = formatResourceId(AWS_ECS_TASK_RESOURCE_TYPE, core.Id) ]
    [#local taskName = core.Name]

    [#local lgId = formatDependentLogGroupId(taskId) ]
    [#local lgName = core.FullAbsolutePath ]

    [#local region = getExistingReference(serviceId, REGION_ATTRIBUTE_TYPE )!regionId ]

    [#local logMetrics = {} ]
    [#list solution.LogMetrics as name,logMetric ]
        [#local logMetrics += {
            "lgMetric" + name : {
                "Id" : formatDependentLogMetricId( lgId, logMetric.Id ),
                "Name" : getMetricName( logMetric.Name, AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE, core.ShortFullName ),
                "Type" : AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE,
                "LogGroupName" : lgName,
                "LogGroupId" : lgId,
                "LogFilter" : logMetric.LogFilter
            }
        }]
    [/#list]

    [#local autoScaling = {}]
    [#if solution.ScalingPolicies?has_content ]
        [#local autoScaling +=
            {
                "scalingTarget" : {
                    "Id" : formatResourceId(AWS_AUTOSCALING_APP_TARGET_RESOURCE_TYPE, core.Id),
                    "Type" : AWS_AUTOSCALING_APP_TARGET_RESOURCE_TYPE
                }
            }
        ]
        [#list solution.ScalingPolicies as name, scalingPolicy ]
            [#local autoScaling +=
                {
                    "scalingPolicy" + name : {
                        "Id" : formatDependentAutoScalingAppPolicyId(serviceId, name),
                        "Name" : formatName(core.FullName, name),
                        "Type" : AWS_AUTOSCALING_APP_POLICY_RESOURCE_TYPE
                    }
                }
            ]
        [/#list]
    [/#if]

    [#assign componentState =
        {
            "Resources" : {
                "service" : {
                    "Id" : serviceId,
                    "Type" : AWS_ECS_SERVICE_RESOURCE_TYPE,
                    "Monitored" : true
                },
                "task" : {
                    "Id" : taskId,
                    "Name" : taskName,
                    "Type" : AWS_ECS_TASK_RESOURCE_TYPE
                }
            } +
            solution.TaskLogGroup?then(
                {
                    "lg" : {
                        "Id" : lgId,
                        "Name" : lgName,
                        "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                    }
                } +
                attributeIfContent("logMetrics", logMetrics),
                {}
            ) +
            attributeIfTrue(
                "taskrole"
                solution.UseTaskRole,
                {
                    "Id" : formatDependentRoleId(taskId),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
                }
            ) +
            attributeIfTrue(
                "securityGroup",
                solution.NetworkMode == "awsvpc",
                {
                    "Id" : formatResourceId( AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE, core.Id ),
                    "Name" : core.FullName,
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                }) +
            attributeIfTrue(
                "executionRole",
                solution.Engine == "fargate",
                {
                    "Id" : formatDependentRoleId(taskId, "execution"),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
                }
            ) +
            autoScaling,
            "Attributes" : {
                "Name" : core.Name
            },
            "Roles" : {
                "Inbound" : {
                    "logwatch" : {
                        "Principal" : "logs." + region + ".amazonaws.com",
                        "LogGroupIds" : [ lgId ]
                    }
                },
                "Outbound" : {}
            }
        }
    ]
[/#macro]

[#macro aws_task_cf_state occurrence parent={} ]
    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]

    [#local parentResources = parent.State.Resources ]
    [#local ecsId = parentResources["cluster"].Id ]

    [#local taskId = formatResourceId(AWS_ECS_TASK_RESOURCE_TYPE, core.Id) ]
    [#local taskName = core.Name]
    [#local taskRoleId = formatDependentRoleId(taskId)]

    [#local executionRoleId = formatDependentRoleId(taskId, "execution")]

    [#local lgId = formatDependentLogGroupId(taskId) ]
    [#local lgName = core.FullAbsolutePath ]

    [#local region = getExistingReference(taskId, REGION_ATTRIBUTE_TYPE )]

    [#local logMetrics = {} ]
    [#list solution.LogMetrics as name,logMetric ]
        [#local logMetrics += {
            "lgMetric" + name : {
                "Id" : formatDependentLogMetricId( lgId, logMetric.Id ),
                "Name" : getMetricName( logMetric.Name, AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE, core.ShortFullName ),
                "Type" : AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE,
                "LogGroupName" : lgName,
                "LogGroupId" : lgId,
                "LogFilter" : logMetric.LogFilter
            }
        }]
    [/#list]

    [#local schedules = {}]
    [#if solution.Schedules?has_content ]
        [#list solution.Schedules?values as schedule ]
            [#local schedules = mergeObjects(schedules, {
                    schedule.Id : {
                        "schedule" : {
                            "Id" : formatEventRuleId(occurrence, "schedule", schedule.Id),
                            "Type" : AWS_EVENT_RULE_RESOURCE_TYPE,
                            "IncludeInDeploymentState" : false
                        }
                    }
            })]
        [/#list]
    [/#if]

    [#assign componentState =
        {
            "Resources" : {
                "task" : {
                    "Id" : taskId,
                    "Name" : taskName,
                    "Type" : AWS_ECS_TASK_RESOURCE_TYPE
                },
                "schedules" : schedules
            } +
            solution.TaskLogGroup?then(
                {
                    "lg" : {
                        "Id" : lgId,
                        "Name" : lgName,
                        "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                    }
                } +
                attributeIfContent("logMetrics", logMetrics),
                {}
            ) +
            attributeIfTrue(
                "taskrole"
                solution.UseTaskRole,
                {
                    "Id" : taskRoleId,
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
                }
            ) +
            attributeIfContent(
                "scheduleRole",
                solution.Schedules,
                {
                    "Id" : formatDependentRoleId(taskId, "schedule"),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
                }
            ) +
            attributeIfTrue(
                "securityGroup",
                solution.NetworkMode == "awsvpc",
                {
                    "Id" : formatResourceId( AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE, core.Id ),
                    "Name" : core.FullName,
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                }) +
            attributeIfTrue(
                "executionRole",
                solution.Engine == "fargate",
                {
                    "Id" : executionRoleId,
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
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
                "Inbound" : {
                    "logwatch" : {
                        "Principal" : "logs." + region + ".amazonaws.com",
                        "LogGroupIds" : [ lgId ]
                    }
                },
                "Outbound" : {
                    "run" :
                        ecsTaskRunPermission(ecsId) +
                        solution.UseTaskRole?then(
                            iamPassRolePermission(
                                getReference(taskRoleId, ARN_ATTRIBUTE_TYPE)
                            ),
                            []
                        ) +
                        (solution.Engine == "fargate")?then(
                            iamPassRolePermission(
                                getReference(executionRoleId, ARN_ATTRIBUTE_TYPE)
                            ),
                            []
                        )
                }
            }
        }
    ]
[/#macro]
