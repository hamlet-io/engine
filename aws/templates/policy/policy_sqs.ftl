[#-- SQS --]

[#macro sqsStatement actions id]
    [@policyStatement 
        actions
        getKey(formatArnAttributeId(id))
    /]
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

[#macro sqsReadStatement id]
    [@sqsStatement "sqs:SendMessage*" id /]
[/#macro]


