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

        [#if resourceCount > 0],[/#if]
        [#switch solutionListMode]
            [#case "definition"]
                "${sqsId}":{
                    "Type" : "AWS::SQS::Queue",
                    "Properties" : {
                        [#if sqs.Name != "SQS"]
                            "QueueName" : "${formatName(
                                                sqs.Name,
                                                sqsInstance)}"
                        [#else]
                            "QueueName" : "${formatName(
                                                productName,
                                                segmentName,
                                                componentName,
                                                sqsInstance)}"
                        [/#if]
                        [#if sqsInstance.Internal.DelaySeconds != -1],"DelaySeconds" : ${sqsInstance.Internal.DelaySeconds?c}[/#if]
                        [#if sqsInstance.Internal.MaximumMessageSize != -1],"MaximumMessageSize" : ${sqsInstance.Internal.MaximumMessageSize?c}[/#if]
                        [#if sqsInstance.Internal.MessageRetentionPeriod != -1],"MessageRetentionPeriod" : ${sqsInstance.Internal.MessageRetentionPeriod?c}[/#if]
                        [#if sqsInstance.Internal.ReceiveMessageWaitTimeSeconds != -1],"ReceiveMessageWaitTimeSeconds" : ${sqsInstance.Internal.ReceiveMessageWaitTimeSeconds?c}[/#if]
                        [#if sqsInstance.Internal.VisibilityTimeout != -1],"VisibilityTimeout" : ${sqsInstance.Internal.VisibilityTimeout?c}[/#if]
                    }
                }
                [#break]
    
            [#case "outputs"]
                [@outputSQS sqsId /],
                [@outputSQSUrl sqsId /],
                [@outputArn sqsId /]
                [#break]
    
        [/#switch]
        [#assign resourceCount += 1]
    [/#list]
[/#if]
