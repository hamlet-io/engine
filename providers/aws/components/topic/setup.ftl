[#ftl]
[#macro aws_topic_cf_generationcontract_solution occurrence ]
    [@addDefaultGenerationContract subsets="template" /]
[/#macro]

[#macro aws_topic_cf_setup_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]
    [#local resources = occurrence.State.Resources]

    [#local topicId = resources["topic"].Id ]
    [#local topicName = resources["topic"].Name ]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "Encryption" ] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]
    [#local cmkKeyId = baselineComponentIds["Encryption"] ]

    [#if deploymentSubsetRequired(TOPIC_COMPONENT_TYPE, true)]
        [@createSNSTopic
            id=topicId
            name=topicName
            encrypted=solution.Encrypted
            kmsKeyId=cmkKeyId
            fixedName=solution.FixedName
        /]
    [/#if]

        [#-- LB level Alerts --]
    [#if deploymentSubsetRequired(TOPIC_COMPONENT_TYPE) ]
        [#list solution.Alerts?values as alert ]

            [#local monitoredResources = getMonitoredResources(core.Id, resources, alert.Resource)]
            [#list monitoredResources as name,monitoredResource ]

                [@debug message="Monitored resource" context=monitoredResource enabled=false /]

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
    [/#if]

    [#list occurrence.Occurrences![] as subOccurrence]

        [#local core = subOccurrence.Core ]
        [#local solution = subOccurrence.Configuration.Solution ]
        [#local resources = subOccurrence.State.Resources ]

        [#local subscriptionDependencies = []]

        [#switch core.Type]

            [#case TOPIC_SUBSCRIPTION_COMPONENT_TYPE  ]
                [#local subscriptionId = resources["subscription"].Id ]

                [#local links = solution.Links ]

                [#list links as linkId,link]

                    [#local linkTarget = getLinkTarget(occurrence, link) ]

                    [@debug message="Link Target" context=linkTarget enabled=false /]

                    [#if !linkTarget?has_content]
                        [#continue]
                    [/#if]

                    [#local linkTargetCore = linkTarget.Core ]
                    [#local linkTargetConfiguration = linkTarget.Configuration ]
                    [#local linkTargetResources = linkTarget.State.Resources ]
                    [#local linkTargetAttributes = linkTarget.State.Attributes ]

                    [#local endpoint = ""]
                    [#local protocol = ""]
                    [#local deliveryPolicy = {}]

                    [#switch linkTargetCore.Type ]
                        [#case "external" ]
                        [#case EXTERNALSERVICE_COMPONENT_TYPE ]
                            [#local endpoint = linkTargetAttributes["SUBSCRIPTION_ENDPOINT"]!"" ]
                            [#local protocol = linkTargetAttributes["SUBSCRIPTION_PROTOCOL"]!"" ]

                            [#if ! endpoint?has_content && ! protocol?has_content ]
                                [@fatal
                                    message="Subscription protocol or endpoints not found"
                                    context=link
                                    detail="External link Attributes Required SUBSCRIPTION_ENDPOINT - SUBSCRIPTION_PROTOCOL"
                                /]
                            [/#if]
                            [#break]

                        [#case LAMBDA_FUNCTION_COMPONENT_TYPE ]
                            [#local endpoint = linkTargetAttributes["ARN"] ]
                            [#local protocol = "lambda"]
                            [#break]

                        [#case SQS_COMPONENT_TYPE]
                            [#local endpoint = linkTargetAttributes["ARN"] ]
                            [#local protocol = "sqs" ]
                            [#break]
                    [/#switch]

                    [#if ! endpoint?has_content && ! protocol?has_content ]
                        [@fatal
                            message="Subscription protocol or endpoints not found"
                            context=link
                            detail="Could not determine protocol and endpoint for link"
                        /]
                    [/#if]


                    [#switch protocol ]
                        [#case "http"]
                        [#case "https" ]
                            [#local deliveryPolicy = getSNSDeliveryPolicy(solution.DeliveryPolicy) ]
                            [#break]
                    [/#switch]

                    [#if deploymentSubsetRequired(TOPIC_COMPONENT_TYPE, true)]
                        [@createSNSSubscription
                            id=formatId(subscriptionId, link.Id)
                            topicId=topicId
                            endpoint=endpoint
                            protocol=protocol
                            rawMessageDelivery=solution.RawMessageDelivery
                            deliveryPolicy=deliveryPolicy
                            dependencies=subscriptionDependencies
                        /]
                    [/#if]
                [/#list]
                [#break]
        [/#switch]
    [/#list]
[/#macro]
