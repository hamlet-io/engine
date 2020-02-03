[#ftl]

[#macro aws_lambda_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]

    [#assign componentState =
        {
            "Resources" : {
                "lambda" : {
                    "Id" : formatResourceId(AWS_LAMBDA_RESOURCE_TYPE, core.Id),
                    "Name" : core.FullName,
                    "Type" : AWS_LAMBDA_RESOURCE_TYPE
                }
            },
            "Attributes" : {},
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]

[#macro aws_function_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution ]

    [#local id = formatResourceId(AWS_LAMBDA_FUNCTION_RESOURCE_TYPE, core.Id)]

    [#local versionOutputId = formatResourceId(AWS_LAMBDA_VERSION_RESOURCE_TYPE, core.Id) ]

    [#if solution.FixedCodeVersion.NewVersionOnDeploy ]
        [#local versionId = formatId(versionOutputId, runId )]
    [#else]
        [#local versionId = versionOutputId]
    [/#if]

    [#local region = getExistingReference(id, REGION_ATTRIBUTE_TYPE)!regionId]

    [#local lgId = formatLogGroupId(core.Id)]
    [#local lgName = formatAbsolutePath("aws", "lambda", core.FullName)]

    [#local fixedCodeVersion = isPresent(solution.FixedCodeVersion) ]

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

    [#assign componentState =
        {
            "Resources" : {
                "function" : {
                    "Id" : id,
                    "Name" : core.FullName,
                    "Type" : AWS_LAMBDA_FUNCTION_RESOURCE_TYPE,
                    "Monitored" : true
                },
                "lg" : {
                    "Id" : formatLogGroupId(core.Id),
                    "Name" : lgName,
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
                }
            } +
            attributeIfContent("logMetrics", logMetrics) +
            attributeIfTrue(
                "version",
                fixedCodeVersion,
                {
                    "Id" : versionOutputId,
                    "ResourceId" : versionId,
                    "Type" : AWS_LAMBDA_VERSION_RESOURCE_TYPE
                }
            ),
            "Attributes" : {
                "REGION" : region,
                "ARN" : valueIfTrue(
                            getExistingReference(versionOutputId),
                            fixedCodeVersion
                            formatArn(
                                regionObject.Partition,
                                "lambda",
                                region,
                                accountObject.AWSId,
                                "function:" + core.FullName,
                                true)
                ),
                "NAME" : core.FullName,
                "DEPLOYMENT_TYPE": solution.DeploymentType
            },
            "Roles" : {
                "Inbound" : {
                    "logwatch" : {
                        "Principal" : "logs." + region + ".amazonaws.com",
                        "LogGroupIds" : [ lgId ]
                    }
                },
                "Outbound" : {
                    "default" : "invoke",
                    "invoke" : lambdaInvokePermission(id),
                    "authorise" : lambdaInvokePermission(id),
                    "authorize" : lambdaInvokePermission(id)
                }
            }
        }
    ]
[/#macro]
