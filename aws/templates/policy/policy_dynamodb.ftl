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

[#function dynamodbProducePermission table="*"]
    [#return [] ]
[/#function]

[#function dynamodbConsumePermission table="*"]
    [#return [] ]
[/#function]

[#function dynamodbReadPermission table="*"]
    [#return [] ]
[/#function]

[#function dynamodbWritePermission table="*"]
    [#return [] ]
[/#function]


