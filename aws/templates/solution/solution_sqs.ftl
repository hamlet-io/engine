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
                                        "VersionId" : version.Id,
                                        "VersionName" : version.Name,
                                        "InstanceId" : (sqsInstance.Id == "default")?string("",sqsInstance.Id),
                                        "InstanceName" : (sqsInstance.Id == "default")?string("",sqsInstance.Name),
                                        "DelaySeconds" : ${(sqsInstance.DelaySeconds!version.DelaySeconds!sqs.DelaySeconds!-1)},
                                        "MaximumMessageSize" : ${(sqsInstance.MaximumMessageSize!version.MaximumMessageSize!sqs.MaximumMessageSize!-1)},
                                        "MessageRetentionPeriod" : ${(sqsInstance.MessageRetentionPeriod!version.MessageRetentionPeriod!sqs.MessageRetentionPeriod!-1)},
                                        "ReceiveMessageWaitTimeSeconds" : ${(sqsInstance.ReceiveMessageWaitTimeSeconds!version.ReceiveMessageWaitTimeSeconds!sqs.ReceiveMessageWaitTimeSeconds!-1)},
                                        "VisibilityTimeout" : ${(sqsInstance.VisibilityTimeout!version.VisibilityTimeout!sqs.VisibilityTimeout!-1)}
                                    }
                                }
                            ] ]
                        [/#if]
                    [/#list]
                 [#else]
                    [#assign sqsInstances += [version +
                        {
                            "Internal" : {
                                "VersionId" : "version.Id",
                                "VersionName" : "version.Name",
                                "InstanceId" : "",
                                "InstanceName" : "",
                                "DelaySeconds" : ${(version.DelaySeconds!sqs.DelaySeconds!-1)},
                                "MaximumMessageSize" : ${(version.MaximumMessageSize!sqs.MaximumMessageSize!-1)},
                                "MessageRetentionPeriod" : ${(version.MessageRetentionPeriod!sqs.MessageRetentionPeriod!-1)},
                                "ReceiveMessageWaitTimeSeconds" : ${(version.ReceiveMessageWaitTimeSeconds!sqs.ReceiveMessageWaitTimeSeconds!-1)},
                                "VisibilityTimeout" : ${(version.VisibilityTimeout!sqs.VisibilityTimeout!-1)}
                            }
                        }
                    ]]
                [/#if]
            [/#if]
        [/#list]
    [/#else]
        [#assign sqsInstances += [sqs +
            {
                "Internal" : {
                    "VersionId" : "",
                    "VersionName" : "",
                    "InstanceId" : "",
                    "InstanceName" : "",
                    "DelaySeconds" : ${(sqs.DelaySeconds!-1)},
                    "MaximumMessageSize" : ${(sqs.MaximumMessageSize!-1)},
                    "MessageRetentionPeriod" : ${(sqs.MessageRetentionPeriod!-1)},
                    "ReceiveMessageWaitTimeSeconds" : ${(sqs.ReceiveMessageWaitTimeSeconds!-1)},
                    "VisibilityTimeout" : ${(sqs.VisibilityTimeout!-1)}
                }
            }
        ]]
    [/#if]

    [#list sqsInstances as sqsInstance]
        [#assign sqsIdStem = formatId(typedComponentIdStem,
                                    sqsInstance.Internal.VersionId,
                                    sqsInstance.Internal.InstanceId)]
        [#if resourceCount > 0],[/#if]
        [#switch solutionListMode]
            [#case "definition"]
                "${sqsIdStem}":{
                    "Type" : "AWS::SQS::Queue",
                    "Properties" : {
                        [#if sqs.Name != "SQS"]
                            "QueueName" : "${formatName(sqs.Name,
                                                        sqsInstance.Internal.VersionName,
                                                        sqsInstance.Internal.InstanceName)])}"
                        [#else]
                            "QueueName" : "${formatName(productName, environmentName, component.Name,
                                                        sqsInstance.Internal.VersionName,
                                                        sqsInstance.Internal.InstanceName)])}"
                        [/#if]
                        [#if sqsInstance.DelaySeconds != -1],"DelaySeconds" : ${sqsInstance.DelaySeconds?c}[/#if]
                        [#if sqsInstance.MaximumMessageSize != -1],"MaximumMessageSize" : ${sqsInstance.MaximumMessageSize?c}[/#if]
                        [#if sqsInstance.MessageRetentionPeriod != -1],"MessageRetentionPeriod" : ${sqsInstance.MessageRetentionPeriod?c}[/#if]
                        [#if sqsInstance.ReceiveMessageWaitTimeSeconds != -1],"ReceiveMessageWaitTimeSeconds" : ${sqsInstance.ReceiveMessageWaitTimeSeconds?c}[/#if]
                        [#if sqsInstance.VisibilityTimeout != -1],"VisibilityTimeout" : ${sqsInstance.VisibilityTimeout?c}[/#if]
                    }
                }
                [#break]
    
            [#case "outputs"]
                "${sqsIdStem}" : {
                    "Value" : { "Fn::GetAtt" : ["${sqsIdStem}", "QueueName"] }
                },
                "${formatId(sqsIdStem, "url")}" : {
                    "Value" : { "Ref" : "${sqsIdStem}" }
                },
                "${formatId(sqsIdStem, "arn")}" : {
                    "Value" : { "Fn::GetAtt" : ["${sqsIdStem}", "Arn"] }
                }
                [#break]
    
        [/#switch]
        [#assign resourceCount += 1]
    [/#list]
[/#if]
