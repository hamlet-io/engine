[#ftl]
[#macro aws_sqs_cf_solution occurrence]
    [@cfDebug listMode occurrence false /]
    [#if deploymentSubsetRequired("sqs", true)]
        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]

        [#assign sqsId = resources["queue"].Id ]
        [#assign sqsName = resources["queue"].Name ]

        [#assign dlqRequired = (resources["dlq"]!{})?has_content ]

        [#if dlqRequired ]
            [#assign dlqId = resources["dlq"].Id ]
            [#assign dlqName = resources["dlq"].Name ]
            [@createSQSQueue
                mode=listMode
                id=dlqId
                name=dlqName
                retention=1209600
                receiveWait=20
            /]
        [/#if]

        [@createSQSQueue
            mode=listMode
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

            [#assign monitoredResources = getMonitoredResources(resources, alert.Resource)]
            [#list monitoredResources as name,monitoredResource ]

                [#switch alert.Comparison ]
                    [#case "Threshold" ]
                        [@createCountAlarm
                            mode=listMode
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