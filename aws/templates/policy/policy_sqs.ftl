[#-- SQS --]

[#macro sqsPolicyHeader id]
    "${id}": {
        "Type" : "AWS::IAM::QueuePolicy",
        "Properties" : {
            "PolicyDocument" : {
                "Version": "2012-10-17",
                "Statement": [
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

[#macro sqsWriteStatement id principals="" resources=""]
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

