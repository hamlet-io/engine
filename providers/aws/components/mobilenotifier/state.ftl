[#ftl]

[#function formatMobileNotifierLogGroupId engine name failure=false]
    [#local failureId = valueIfTrue("failure", failure, "") ]
    [#return
        valueIfTrue(
            formatAccountLogGroupId("sms", failureId),
            engine == MOBILENOTIFIER_SMS_ENGINE,
            formatLogGroupId(name, failureId)
        ) ]
[/#function]

[#macro aws_mobilenotifier_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#assign componentState =
        {
            "Resources" : {
                "role" : {
                    "Id" : formatDependentRoleId( core.Id ),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
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
[/#macro]

[#macro aws_mobilenotifierplatform_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local id = formatResourceId(AWS_SNS_PLATFORMAPPLICATION_RESOURCE_TYPE, core.Id) ]
    [#local name = core.FullName ]
    [#local topicPrefix = core.ShortFullName]
    [#local engine = solution.Engine!core.SubComponent.Name?upper_case  ]

    [#local lgId = formatMobileNotifierLogGroupId(engine, name, false) ]
    [#local lgName = formatMobileNotifierLogGroupName(engine, name, false)]

    [#local lgFailureId = formatMobileNotifierLogGroupId(engine, name, true) ]
    [#local lgFailureName = formatMobileNotifierLogGroupName(engine, name, true)]

    [#local region = contentIfContent(getExistingReference(id, REGION_ATTRIBUTE_TYPE), regionId) ]

    [#local logMetrics = {} ]
    [#list solution.LogMetrics as name,logMetric ]
        [#local logMetrics += {
            "lgMetric" + name + "success" : {
                "Id" : formatDependentLogMetricId( lgId, logMetric.Id ),
                "Name" : getMetricName( logMetric.Name, AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE, core.ShortFullName ),
                "Type" : AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE,
                "LogGroupName" : lgName,
                "LogGroupId" : lgId,
                "LogFilter" : logMetric.LogFilter
            },
            "lgMetric" + name + "failure" : {
                "Id" : formatDependentLogMetricId( lgFailureId, logMetric.Id ),
                "Name" : getMetricName( logMetric.Name, AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE, core.ShortFullName ),
                "Type" : AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE,
                "LogGroupName" : lgFailureName,
                "LogGroupId" : lgFailureId,
                "LogFilter" : logMetric.LogFilter
            }
        }]
    [/#list]

    [#assign componentState =
        {
            "Resources" : {
                "platformapplication" : {
                    "Id" : id,
                    "Name" : core.FullName,
                    "Engine" : engine,
                    "Type" : AWS_SNS_PLATFORMAPPLICATION_RESOURCE_TYPE,
                    "Monitored" : true
                } +
                attributeIfTrue(
                    "Deployed",
                    ( engine == MOBILENOTIFIER_SMS_ENGINE),
                    true
                ),
                "lg" : {
                    "Id" : lgId,
                    "Name" : lgName,
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
                },
                "lgfailure" : {
                    "Id" : lgFailureId,
                    "Name" : lgFailureName,
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
                }
            } +
            attributeIfContent("logMetrics", logMetrics),
            "Attributes" : {
                "ARN" : (engine == MOBILENOTIFIER_SMS_ENGINE)?then(
                            formatArn(
                                regionObject.Partition,
                                "sns",
                                region,
                                accountObject.AWSId,
                                "smsPlaceHolder"
                            ),
                            getExistingReference(id, ARN_ATTRIBUTE_TYPE)
                ),
                "ENGINE" : engine,
                "TOPIC_PREFIX" : topicPrefix
            },
            "Roles" : {
                "Inbound" : {
                    "logwatch" : {
                        "Principal" : "logs." + region + ".amazonaws.com",
                        "LogGroupIds" : [ lgId, lgFailureId ]
                    }
                },
                "Outbound" : {
                    "default" : "publish",
                    "publish" : (engine == MOBILENOTIFIER_SMS_ENGINE)?then(
                        snsSMSPermission(),
                        snsPublishPlatformApplication(name, engine, topicPrefix)
                    )
                }
            }
        }
    ]
[/#macro]