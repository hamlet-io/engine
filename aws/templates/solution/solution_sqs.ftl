[#-- SQS --]
[#if (componentType == "sqs") && deploymentSubsetRequired("sqs", true)]
    [#assign sqs = component.SQS]

    [#list getOccurrences(component, deploymentUnit) as occurrence]
    
        [#assign sqsId = formatComponentSQSId(
                            tier,
                            component,
                            occurrence)]
        [#assign sqsName = (sqs.Name != "SQS")?then(
                                formatName(
                                    sqs.Name,
                                    occurrence),
                                formatName(
                                    productName,
                                    segmentName,
                                    componentName,
                                    occurrence))]
        [#assign sqsDimensions =
            [
                {
                    "Name" : "QueueName",
                    "Value" : sqsName
                }
            ]
        ]
        
        [@createSQSQueue
            mode=solutionListMode
            id=sqsId
            name=sqsName
            delay=occurrence.DelaySeconds
            maximumSize=occurrence.MaximumMessageSize
            retention=occurrence.MessageRetentionPeriod
            receiveWait=occurrence.ReceiveMessageWaitTimeSeconds
            visibilityTimout=occurrence.VisibilityTimeout
        /]

        [#switch solutionListMode]
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
