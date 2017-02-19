[#-- SQS --]
[#if component.SQS??]
    [#assign sqs = component.SQS]
    [#if resourceCount > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
            "sqsX${tier.Id}X${component.Id}":{
                "Type" : "AWS::SQS::Queue",
                "Properties" : {
                    [#if sqs.Name != "SQS"]
                        "QueueName" : "${sqs.Name}"
                    [#else]
                        "QueueName" : "${productName}-${environmentName}-${component.Name}"
                    [/#if]
                    [#if sqs.DelaySeconds??],"DelaySeconds" : ${sqs.DelaySeconds?c}[/#if]
                    [#if sqs.MaximumMessageSize??],"MaximumMessageSize" : ${sqs.MaximumMessageSize?c}[/#if]
                    [#if sqs.MessageRetentionPeriod??],"MessageRetentionPeriod" : ${sqs.MessageRetentionPeriod?c}[/#if]
                    [#if sqs.ReceiveMessageWaitTimeSeconds??],"ReceiveMessageWaitTimeSeconds" : ${sqs.ReceiveMessageWaitTimeSeconds?c}[/#if]
                    [#if sqs.VisibilityTimeout??],"VisibilityTimeout" : ${sqs.VisibilityTimeout?c}[/#if]
                }
            }
            [#break]

        [#case "outputs"]
            "sqsX${tier.Id}X${component.Id}" : {
                "Value" : { "Fn::GetAtt" : ["sqsX${tier.Id}X${component.Id}", "QueueName"] }
            },
            "sqsX${tier.Id}X${component.Id}Xurl" : {
                "Value" : { "Ref" : "sqsX${tier.Id}X${component.Id}" }
            },
            "sqsX${tier.Id}X${component.Id}Xarn" : {
                "Value" : { "Fn::GetAtt" : ["sqsX${tier.Id}X${component.Id}", "Arn"] }
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]