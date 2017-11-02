[#-- dynamodb --]

[#function getDynamodbTableStatement actions table="*" principals="" conditions=""]
    [#return
        [
            getPolicyStatement(
                actions,
                formatRegionalArn(
                    "dynamodb",
                    formatTypedArnResource(
                        "table", 
                        productName + "_" + segmentName + "_" + table,
                        "/")),
                principals,
                conditions)
        ]
    ]
[/#function]

[#function dynamodbAdminPermission table="*"]
    [#return
        getDynamodbTableStatement(
            "dynamodb:*",
            table) ]
[/#function]

[#function dynamodbAllPermission table="*"]
    [#return
        getDynamodbTableStatement(
            "dynamodb:*",
            table)]
[/#function]

[#function dynamodbReadPermission table="*"]
    [#return
        getDynamodbTableStatement(
            [
                "dynamodb:BatchGetItem",
                "dynamodb:GetItem",
                "dynamodb:ListTagsOfResource",
                "dynamodb:Query"
            ],
            table)]
[/#function]

[#function dynamodbWritePermission table="*"]
    [#return
        getDynamodbTableStatement(
            [
                "dynamodb:BatchWriteItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:TagResource",
                "dynamodb:UntagResource"
            ],
            table)]
[/#function]

[#function dynamodbDeletePermission table="*"]
    [#return
        getDynamodbTableStatement(
            [
                "dynamodb:DeleteItem"
            ],
            table)]
[/#function]

[#function dynamodbProducePermission table="*"]
    [#return
        dynamodbReadPermission(table) +
        dynamodbWritePermission(table)]
[/#function]

[#function dynamodbConsumePermission table="*"]
    [#return
        dynamodbReadPermission(table) +
        dynamodbDeletePermission(table)]
[/#function]


