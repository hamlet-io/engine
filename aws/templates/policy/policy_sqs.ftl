[#-- SQS --]

[#function getSqsStatement actions id principals="" conditions=""]
    [#return
        [
            getPolicyStatement(
                actions,
                getArnReference(id),
                principals,
                conditions)
        ]
    ]
[/#function]

[#macro sqsStatement actions id principals="" conditions=""]
    [@policyStatements getSqsStatement(actions, id, principals, conditions) /]
[/#macro]

[#function getSqsAdminStatement id]
    [#return
        getSqsStatement(
            "sqs:*",
            id)]
[/#function]

[#macro sqsAdminStatement id]
    [@policyStatements getSqsAdminStatement(id) /]
[/#macro]

[#function getSqsAllStatement id]
    [#return
        getSqsStatement(
            [
                "sqs:SendMessage*",
                "sqs:ReceiveMessage*",
                "sqs:ChangeMessage*",
                "sqs:DeleteMessage*",
                "sqs:Get*",
                "sqs:List*"
            ],
            id)]
[/#function]

[#macro sqsAllStatement id]
    [@policyStatements getSqsAllStatement(id) /]
[/#macro]

[#function getSqsProduceStatement id]
    [#return
        getSqsStatement(
            [
                "sqs:SendMessage*",
                "sqs:Get*",
                "sqs:List*"
            ],
            id)]
[/#function]

[#macro sqsProduceStatement id]
    [@policyStatements getSqsProduceStatement(id) /]
[/#macro]

[#function getSqsConsumeStatement id]
    [#return
        getSqsStatement(
            [
                "sqs:ReceiveMessage*",
                "sqs:ChangeMessage*",
                "sqs:DeleteMessage*",
                "sqs:Get*",
                "sqs:List*"
            ],
            id)]
[/#function]

[#macro sqsConsumeStatement id]
    [@policyStatements getSqsConsumeStatement(id) /]
[/#macro]

[#function getSqsWriteStatement id]
    [#return
        getSqsStatement(
            "sqs:SendMessage*",
            id)]
[/#function]

[#macro sqsWriteStatement id]
    [@policyStatements getSqsWriteStatement(id) /]
[/#macro]

[#function getSqsS3WriteStatement id]
    [#return
        getSqsStatement(
            "sqs:SendMessage*",
            id,
            "*",
            {
                "ArnLike" : {
                    "aws:sourceArn" : "arn:aws:s3:::*"
                }
            })]
[/#function]

[#macro sqsS3WriteStatement id]
    [@policyStatements getSqsS3WriteStatement(id) /]
[/#macro]


