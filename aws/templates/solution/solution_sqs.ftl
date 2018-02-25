[#-- SQS --]
[#if (componentType == "sqs") && deploymentSubsetRequired("sqs", true)]
    [#assign sqs = component.SQS]

    [#list getOccurrences(component, tier, component, deploymentUnit) as occurrence]
    
        [#assign sqsId = formatComponentSQSId(
                            tier,
                            component,
                            occurrence)]
        [#assign dlqId = formatDependentSQSId(
                            sqsId,
                            "dlq")]
        [#assign sqsName = (sqs.Name != "SQS")?then(
                                formatName(
                                    sqs.Name,
                                    occurrence),
                                formatName(
                                    productName,
                                    segmentName,
                                    componentName,
                                    occurrence))]
        [#assign dlqName = formatName(
                            sqsName,
                            "dlq")]
        [#assign sqsDimensions =
            [
                {
                    "Name" : "QueueName",
                    "Value" : sqsName
                }
            ]
        ]

        [#assign dlqRequired =
            (occurrence.DeadLetterQueue.Configured &&
                occurrence.DeadLetterQueue.Enabled) ||
            ((environmentObject.Operations.DeadLetterQueue.Enabled)!false)]
        [#if dlqRequired]
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
            delay=occurrence.DelaySeconds
            maximumSize=occurrence.MaximumMessageSize
            retention=occurrence.MessageRetentionPeriod
            receiveWait=occurrence.ReceiveMessageWaitTimeSeconds
            visibilityTimout=occurrence.VisibilityTimeout
            dlq=valueIfTrue(dlqId, dlqRequired, "")
            dlqReceives=
                valueIfTrue(
                  occurrence.DeadLetterQueue.MaxReceives,
                  occurrence.DeadLetterQueue.MaxReceives > 0,
                  (environmentObject.Operations.DeadLetterQueue.MaxReceives)!3)
        /]

        [#switch listMode]
            [#case "dashboard"]
                [#if getExistingReference(sqsId)?has_content]
                    [#assign widgets =
                        [
                            {
                                "Type" : "metric",
                                "Metrics" : [
                                    {
                                        "Namespace" : "AWS/SQS",
                                        "Metric" : "NumberOfMessagesReceived",
                                        "Dimensions" : sqsDimensions
                                    }
                                ],
                                "Title" : "Received",
                                "Width" : 6,
                                "asGraph" : true
                            },
                            {
                                "Type" : "metric",
                                "Metrics" : [
                                    {
                                        "Namespace" : "AWS/SQS",
                                        "Metric" : "ApproximateAgeOfOldestMessage",
                                        "Dimensions" : sqsDimensions,
                                        "Statistic" : "Maximum"
                                    }
                                ],
                                "Title" : "Oldest",
                                "Width" : 6,
                                "asGraph" : true
                            }
                        ]
                    ]
                    [#assign dashboardRows +=
                        [
                            {
                                "Title" : formatName(occurrence),
                                "Widgets" : widgets
                            }
                        ]
                    ]
                [/#if]
                [#break]
        [/#switch]
    [/#list]
[/#if]
