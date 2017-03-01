[#-- SQS --]
[#if component.SQS??]
    [#assign sqs = component.SQS]
    [#if resourceCount > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
            "${formatId("sqs", tier.Id, component.Id)}":{
                "Type" : "AWS::SQS::Queue",
                "Properties" : {
                    [#if sqs.Name != "SQS"]
                        "QueueName" : "${sqs.Name}"
                    [#else]
                        "QueueName" : "${formatName(productName, environmentName, component.Name)}"
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
            "${formatId("sqs", tier.Id, component.Id)}" : {
                "Value" : { "Fn::GetAtt" : ["${formatId("sqs", tier.Id, component.Id)}", "QueueName"] }
            },
            "${formatId("sqs", tier.Id, component.Id, "url")}" : {
                "Value" : { "Ref" : "${formatId("sqs", tier.Id, component.Id)}" }
            },
            "${formatId("sqs", tier.Id, component.Id, "arn")}" : {
                "Value" : { "Fn::GetAtt" : ["${formatId("sqs", tier.Id, component.Id)}", "Arn"] }
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]