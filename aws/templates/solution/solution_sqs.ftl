[#-- SQS --]
[#if componentType == "sqs"]
    [#assign sqs = component.SQS]

    [#assign sqsInstances=[]]
    [#if sqs.Versions??]
        [#list sqs.Versions?values as version]
            [#if deploymentRequired(version, deploymentUnit)]
                [#if version.Instances??]
                    [#list version.Instances?values as sqsInstance]
                        [#if deploymentRequired(sqsInstance, deploymentUnit)]
                            [#assign sqsInstances += [sqsInstance +
                                {
                                    "Internal" : {
                                        "IdExtensions" : [
                                            version.Id, 
                                            (sqsInstance.Id == "default")?
                                                string(
                                                    "",
                                                    sqsInstance.Id)],
                                        "NameExtensions" : [
                                            version.Name,
                                            (sqsInstance.Id == "default")?
                                                string(
                                                    "",
                                                    sqsInstance.Name)],
                                        "DelaySeconds" : sqsInstance.DelaySeconds!version.DelaySeconds!sqs.DelaySeconds!-1,
                                        "MaximumMessageSize" : sqsInstance.MaximumMessageSize!version.MaximumMessageSize!sqs.MaximumMessageSize!-1,
                                        "MessageRetentionPeriod" : sqsInstance.MessageRetentionPeriod!version.MessageRetentionPeriod!sqs.MessageRetentionPeriod!-1,
                                        "ReceiveMessageWaitTimeSeconds" : sqsInstance.ReceiveMessageWaitTimeSeconds!version.ReceiveMessageWaitTimeSeconds!sqs.ReceiveMessageWaitTimeSeconds!-1,
                                        "VisibilityTimeout" : sqsInstance.VisibilityTimeout!version.VisibilityTimeout!sqs.VisibilityTimeout!-1
                                    }
                                }
                            ] ]
                        [/#if]
                    [/#list]
                [#else]
                    [#assign sqsInstances += [version +
                        {
                            "Internal" : {
                                "IdExtensions" : [
                                    version.Id],
                                "NameExtensions" : [
                                    version.Name],
                                "DelaySeconds" : version.DelaySeconds!sqs.DelaySeconds!-1,
                                "MaximumMessageSize" : version.MaximumMessageSize!sqs.MaximumMessageSize!-1,
                                "MessageRetentionPeriod" : version.MessageRetentionPeriod!sqs.MessageRetentionPeriod!-1,
                                "ReceiveMessageWaitTimeSeconds" : version.ReceiveMessageWaitTimeSeconds!sqs.ReceiveMessageWaitTimeSeconds!-1,
                                "VisibilityTimeout" : version.VisibilityTimeout!sqs.VisibilityTimeout!-1
                            }
                        }
                    ]]
                [/#if]
            [/#if]
        [/#list]
    [#else]
        [#assign sqsInstances += [sqs +
            {
                "Internal" : {
                    "IdExtensions" : [],
                    "NameExtensions" : [],
                    "DelaySeconds" : sqs.DelaySeconds!-1,
                    "MaximumMessageSize" : sqs.MaximumMessageSize!-1,
                    "MessageRetentionPeriod" : sqs.MessageRetentionPeriod!-1,
                    "ReceiveMessageWaitTimeSeconds" : sqs.ReceiveMessageWaitTimeSeconds!-1,
                    "VisibilityTimeout" : sqs.VisibilityTimeout!-1
                }
            }
        ]]
    [/#if]

    [#list sqsInstances as sqsInstance]
    
        [#assign sqsId = formatComponentSQSId(
                            tier,
                            component,
                            sqsInstance)]
        [#assign sqsName = (sqs.Name != "SQS")?then(
                                formatName(
                                    sqs.Name,
                                    sqsInstance),
                                formatName(
                                    productName,
                                    segmentName,
                                    componentName,
                                    sqsInstance))]
        [#assign sqsDimensions =
            [
                {
                    "Name" : "QueueName",
                    "Value" : sqsName
                }
            ]
        ]

        [#switch solutionListMode]
            [#case "definition"]
                [@checkIfResourcesCreated /]
                "${sqsId}":{
                    "Type" : "AWS::SQS::Queue",
                    "Properties" : {
                        "QueueName" : "${sqsName}"
                        [#if sqsInstance.Internal.DelaySeconds != -1],"DelaySeconds" : ${sqsInstance.Internal.DelaySeconds?c}[/#if]
                        [#if sqsInstance.Internal.MaximumMessageSize != -1],"MaximumMessageSize" : ${sqsInstance.Internal.MaximumMessageSize?c}[/#if]
                        [#if sqsInstance.Internal.MessageRetentionPeriod != -1],"MessageRetentionPeriod" : ${sqsInstance.Internal.MessageRetentionPeriod?c}[/#if]
                        [#if sqsInstance.Internal.ReceiveMessageWaitTimeSeconds != -1],"ReceiveMessageWaitTimeSeconds" : ${sqsInstance.Internal.ReceiveMessageWaitTimeSeconds?c}[/#if]
                        [#if sqsInstance.Internal.VisibilityTimeout != -1],"VisibilityTimeout" : ${sqsInstance.Internal.VisibilityTimeout?c}[/#if]
                    }
                }
                [@resourcesCreated /]
                [#break]
    
            [#case "outputs"]
                [@outputSQS sqsId /]
                [@outputSQSUrl sqsId /]
                [@outputArn sqsId /]
                [#break]
    
            [#case "dashboard"]
                [#if getKey(sqsId)?has_content]
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
                                "Title" : formatName(sqsInstance),
                                "Widgets" : widgets
                            }
                        ]
                    ]
                [/#if]
                [#break]
        [/#switch]
    [/#list]
[/#if]
