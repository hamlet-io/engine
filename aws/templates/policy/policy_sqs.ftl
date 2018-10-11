[#-- SQS --]

[#function getSqsStatement actions id="" principals="" conditions=""]
    [#return
        [
            getPolicyStatement(
                actions,
                valueIfContent(
                    getArn(id),
                    id,
                    formatRegionalArn("sqs", "*")),
                principals,
                conditions)
        ]
    ]
[/#function]

[#function sqsListQueuesPermission]
    [#return getSqsStatement("sqs:ListQueues") ]
[/#function]

[#function sqsAdminPermission id]
    [#return
        getSqsStatement(
            "sqs:*",
            id) +
        sqsListQueuesPermission() ]
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
            id) +
        sqsListQueuesPermission() ]
[/#function]

[#function sqsProducePermission id]
    [#return
        getSqsStatement(
            [
                "sqs:SendMessage*",
                "sqs:Get*",
                "sqs:List*"
            ],
            id) +
        sqsListQueuesPermission() ]
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
            id) +
        sqsListQueuesPermission() ]
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


