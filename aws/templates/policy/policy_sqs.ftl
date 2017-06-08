[#-- SQS --]

[#macro sqsPolicyHeader id]
    [@policyHeader id "" "QueuePolicy" /]
[/#macro]

[#macro sqsPolicyFooter queueIds]
                ]
            },
            "Queues" :
                [#if queueIds?is_sequence]
                    [
                        [#list queueIds as queue]
                            { "Ref" : "${getKey(
                                            formatUrlAttributeId(
                                                queue))}" }
                            [#if queueIds?last != queue],[/#if]
                        [/#list]
                    ]
                [#else]
                    { "Ref" : "${getKey(
                                    formatUrlAttributeId(
                                        queueIds))}" }
                [/#if]
        }
    }
[/#macro]

[#macro sqsStatement actions id principals="" conditions=""]
    [@policyStatement 
        actions
        getKey(formatArnAttributeId(id))
        "Allow"
        principals
        conditions
    /]
[/#macro]

[#macro sqsAdminStatement id]
    [@sqsStatement "sqs:*" id /]
[/#macro]

[#macro sqsAllStatement id]
    [@sqsStatement
        [
            "sqs:SendMessage*",
            "sqs:ReceiveMessage*",
            "sqs:ChangeMessage*",
            "sqs:DeleteMessage*",
            "sqs:Get*",
            "sqs:List*"
        ]
        id
    /]
[/#macro]

[#macro sqsProduceStatement id]
    [@sqsStatement
        [
            "sqs:SendMessage*",
            "sqs:Get*",
            "sqs:List*"
        ]
        id
    /]
[/#macro]

[#macro sqsConsumeStatement id]
    [@sqsStatement
        [
            "sqs:ReceiveMessage*",
            "sqs:ChangeMessage*",
            "sqs:DeleteMessage*",
            "sqs:Get*",
            "sqs:List*"
        ]
        id
    /]
[/#macro]

[#macro sqsWriteStatement id]
    [@sqsStatement "sqs:SendMessage*" id /]
[/#macro]

[#macro sqsS3WriteStatement id]
    [@sqsWriteStatement
        id
        "*"
        {
            "ArnLike" : {
                "aws:sourceArn" : "arn:aws:s3:::*"
            }
        }
    /]
[/#macro]

