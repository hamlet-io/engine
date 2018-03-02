[#-- SQS --]
[#if (componentType == "sqs") && deploymentSubsetRequired("sqs", true)]
    [#assign sqs = component.SQS]

    [#list requiredOccurrences(
            getOccurrences(component, tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign configuration = occurrence.Configuration ]
        [#assign resources = occurrence.State.Resources ]

        [#assign sqsId = resources["primary"].Id ]
        [#assign sqsName = resources["primary"].Name ]
        [#assign dlqId = resources["dlq"].Id ]
        [#assign dlqName = resources["dlq"].Name ]

        [#assign sqsDimensions =
            [
                {
                    "Name" : "QueueName",
                    "Value" : sqsName
                }
            ]
        ]

        [#assign dlqRequired =
            (configuration.DeadLetterQueue.Configured &&
                configuration.DeadLetterQueue.Enabled) ||
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
            delay=configuration.DelaySeconds
            maximumSize=configuration.MaximumMessageSize
            retention=configuration.MessageRetentionPeriod
            receiveWait=configuration.ReceiveMessageWaitTimeSeconds
            visibilityTimout=configuration.VisibilityTimeout
            dlq=valueIfTrue(dlqId, dlqRequired, "")
            dlqReceives=
                valueIfTrue(
                  configuration.DeadLetterQueue.MaxReceives,
                  configuration.DeadLetterQueue.MaxReceives > 0,
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
