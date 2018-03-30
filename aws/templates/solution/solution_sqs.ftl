[#-- SQS --]
[#if (componentType == "sqs") && deploymentSubsetRequired("sqs", true)]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]

        [#assign sqsId = resources["queue"].Id ]
        [#assign sqsName = resources["queue"].Name ]
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
            (solution.DeadLetterQueue.Configured &&
                solution.DeadLetterQueue.Enabled) ||
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
            delay=solution.DelaySeconds
            maximumSize=solution.MaximumMessageSize
            retention=solution.MessageRetentionPeriod
            receiveWait=solution.ReceiveMessageWaitTimeSeconds
            visibilityTimout=solution.VisibilityTimeout
            dlq=valueIfTrue(dlqId, dlqRequired, "")
            dlqReceives=
                valueIfTrue(
                  solution.DeadLetterQueue.MaxReceives,
                  solution.DeadLetterQueue.MaxReceives > 0,
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
