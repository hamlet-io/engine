[#ftl]
[#macro aws_sqs_cf_generationcontract_solution occurrence ]
    [@addDefaultGenerationContract subsets="template" /]
[/#macro]

[#macro aws_sqs_cf_setup_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#if deploymentSubsetRequired("sqs", true)]

        [#local core = occurrence.Core ]
        [#local solution = occurrence.Configuration.Solution ]
        [#local resources = occurrence.State.Resources ]

        [#local sqsId = resources["queue"].Id ]
        [#local sqsName = resources["queue"].Name ]

        [#local dlqRequired = (resources["dlq"]!{})?has_content ]

        [#if dlqRequired ]
            [#local dlqId = resources["dlq"].Id ]
            [#local dlqName = resources["dlq"].Name ]
            [@createSQSQueue
                id=dlqId
                name=dlqName
                retention=1209600
                receiveWait=20
            /]
        [/#if]

        [@createSQSQueue
            id=sqsId
            name=sqsName
            delay=solution.DelaySeconds
            maximumSize=solution.MaximumMessageSize
            retention=solution.MessageRetentionPeriod
            receiveWait=solution.ReceiveMessageWaitTimeSeconds
            visibilityTimout=solution.VisibilityTimeout
            dlq=valueIfTrue(dlqId!"", dlqRequired, "")
            dlqReceives=
                valueIfTrue(
                solution.DeadLetterQueue.MaxReceives,
                solution.DeadLetterQueue.MaxReceives > 0,
                (environmentObject.Operations.DeadLetterQueue.MaxReceives)!3)
        /]

        [#list solution.Alerts?values as alert ]

            [#local monitoredResources = getMonitoredResources(core.Id, resources, alert.Resource)]
            [#list monitoredResources as name,monitoredResource ]

                [#switch alert.Comparison ]
                    [#case "Threshold" ]
                        [@createAlarm
                            id=formatDependentAlarmId(monitoredResource.Id, alert.Id )
                            severity=alert.Severity
                            resourceName=core.FullName
                            alertName=alert.Name
                            actions=getCWAlertActions(occurrence, solution.Profiles.Alert, alert.Severity )
                            metric=getMetricName(alert.Metric, monitoredResource.Type, core.ShortFullName)
                            namespace=getResourceMetricNamespace(monitoredResource.Type, alert.Namespace)
                            description=alert.Description!alert.Name
                            threshold=alert.Threshold
                            statistic=alert.Statistic
                            evaluationPeriods=alert.Periods
                            period=alert.Time
                            operator=alert.Operator
                            reportOK=alert.ReportOk
                            unit=alert.Unit
                            missingData=alert.MissingData
                            dimensions=getResourceMetricDimensions(monitoredResource, resources)
                        /]
                    [#break]
                [/#switch]
            [/#list]
        [/#list]

        [#list solution.Links as linkId,link]

            [#local linkTarget = getLinkTarget(occurrence, link) ]

            [@debug message="Link Target" context=linkTarget enabled=false /]

            [#if !linkTarget?has_content]
                [#continue]
            [/#if]

            [#local linkTargetCore = linkTarget.Core ]
            [#local linkTargetResources = linkTarget.State.Resources ]
            [#local linkTargetRoles = linkTarget.State.Roles ]
            [#local linkDirection = linkTarget.Direction ]
            [#local linkRole = linkTarget.Role]

            [#switch linkDirection ]
                [#case "inbound" ]
                    [#switch linkRole ]
                        [#case "invoke" ]
                            [#switch linkTargetCore.Type ]
                                [#case TOPIC_COMPONENT_TYPE]
                                    [#local topicId = linkTargetResources["topic"].Id ]
                                    [#local policyId =
                                            formatDependentPolicyId(
                                                sqsId,
                                                topicId) ]

                                    [@createSQSPolicy
                                        id=policyId
                                        queues=sqsId
                                        statements=sqsWritePermission(
                                                        sqsId,
                                                        {"Service" : linkTargetRoles.Inbound["invoke"].Principal},
                                                        {
                                                            "ArnEquals" : {
                                                                "aws:sourceArn" : linkTargetRoles.Inbound["invoke"].SourceArn
                                                            }
                                                        },
                                                        true)
                                    /]
                                    [#break]
                            [/#switch]
                            [#break]
                    [/#switch]
                    [#break]
            [/#switch]
        [/#list]
    [/#if]
[/#macro]
