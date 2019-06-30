[#ftl]
[#macro aws_sqs_cf_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#if deploymentSubsetRequired("genplan", false)]
        [@addDefaultGenerationPlan subsets="template" /]
        [#return]
    [/#if]

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

            [#local monitoredResources = getMonitoredResources(resources, alert.Resource)]
            [#list monitoredResources as name,monitoredResource ]

                [#switch alert.Comparison ]
                    [#case "Threshold" ]
                        [@createCountAlarm
                            id=formatDependentAlarmId(monitoredResource.Id, alert.Id )
                            severity=alert.Severity
                            resourceName=core.FullName
                            alertName=alert.Name
                            actions=[
                                getReference(formatSegmentSNSTopicId())
                            ]
                            metric=getMetricName(alert.Metric, monitoredResource.Type, core.ShortFullName)
                            namespace=getResourceMetricNamespace(monitoredResource.Type)
                            description=alert.Description!alert.Name
                            threshold=alert.Threshold
                            statistic=alert.Statistic
                            evaluationPeriods=alert.Periods
                            period=alert.Time
                            operator=alert.Operator
                            reportOK=alert.ReportOk
                            missingData=alert.MissingData
                            dimensions=getResourceMetricDimensions(monitoredResource, resources)
                            dependencies=monitoredResource.Id
                        /]
                    [#break]
                [/#switch]
            [/#list]
        [/#list]
    [/#if]
[/#macro]
