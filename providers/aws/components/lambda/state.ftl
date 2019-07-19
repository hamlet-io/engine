[#ftl]

[#macro aws_lambda_cf_state occurrence parent={} baseState={}  ]
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
            "Attributes" : {
                "REGION" : regionId
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]

[#macro aws_function_cf_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution ]

    [#local parentSolution = parent.Configuration.Solution ]

    [#local id = formatResourceId(AWS_LAMBDA_FUNCTION_RESOURCE_TYPE, core.Id)]
    [#local versionId = formatResourceId(AWS_LAMBDA_VERSION_RESOURCE_TYPE, core.Id )]

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
                    "Id" : versionId,
                    "Type" : AWS_LAMBDA_VERSION_RESOURCE_TYPE
                }
            ),
            "Attributes" : {
                "REGION" : regionId,
                "ARN" : valueIfTrue(
                            getExistingReference( versionId ),
                            fixedCodeVersion
                            formatArn(
                                regionObject.Partition,
                                "lambda",
                                regionId,
                                accountObject.AWSId,
                                "function:" + core.FullName,
                                true)
                ),
                "NAME" : core.FullName,
                "DEPLOYMENT_TYPE": parentSolution.DeploymentType
            },
            "Roles" : {
                "Inbound" : {
                    "logwatch" : {
                        "Principal" : "logs." + regionId + ".amazonaws.com",
                        "LogGroupIds" : [ lgId ]
                    }
                },
                "Outbound" : {
                    "default" : "invoke",
                    "invoke" : lambdaInvokePermission(id)
                }
            }
        }
    ]
[/#macro]