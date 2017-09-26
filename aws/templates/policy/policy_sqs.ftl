[#-- SQS --]

[#function getSqsStatement actions id principals="" conditions=""]
    [#return
        [
            getPolicyStatement(
                actions,
                getReference(id, ARN_ATTRIBUTE_TYPE),
                principals,
                conditions)
        ]
    ]
[/#function]

[#function sqsAdminPermission id]
    [#return
        getSqsStatement(
            "sqs:*",
            id)]
[/#function]

[#function sqsAllPermission id]
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

[#function sqsProducePermission id]
    [#return
        getSqsStatement(
            [
                "sqs:SendMessage*",
                "sqs:Get*",
                "sqs:List*"
            ],
            id)]
[/#function]

[#function sqsConsumePermission id]
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

[#function sqsWritePermission id]
    [#return
        getSqsStatement(
            "sqs:SendMessage*",
            id)]
[/#function]

[#function sqsS3WritePermission id]
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


