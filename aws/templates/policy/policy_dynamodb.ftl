[#-- dynamodb --]

[#function getDynamodbStatement actions tables=[] streams=[] indexes=[] principals="" conditions=""]
    [#local result = [] ]
    [#if tables?has_content]
        [#list asArray(tables) as table]
            [#local tableResource=["table", productName + "_" + segmentName + "_" + table] ]
            [#if !(streams?has_content || indexes?has_content)]
                [#local result +=
                    [
                        getPolicyStatement(
                            actions,
                            formatRegionalArn(
                                "dynamodb",
                                concatenate(tableResource, "/")),
                            principals,
                            conditions)
                    ]
                ]
            [#else]
                [#list asArray(streams) as stream]
                    [#local result +=
                        [
                            getPolicyStatement(
                                actions,
                                formatRegionalArn(
                                    "dynamodb",
                                    concatenate(tableResource + ["stream", stream], "/")),
                                principals,
                                conditions)
                        ]
                    ]
                [/#list]
                [#list asArray(indexes) as index]
                    [#local result +=
                        [
                            getPolicyStatement(
                                actions,
                                formatRegionalArn(
                                    "dynamodb",
                                    concatenate(tableResource + ["index", index], "/")),
                                principals,
                                conditions)
                        ]
                    ]
                [/#list]
            [/#if]
        [/#list]
    [#else]
        [#local result +=
            [
                getPolicyStatement(
                    actions,
                    formatRegionalArn(
                        "dynamodb",
                        "*"),
                    principals,
                    conditions)
            ]
        ]
    [/#if]
    [#return result]
[/#function]

[#function dynamodbReadPermission tables="*"]
    [#return
        getDynamodbStatement(
            [
                "dynamodb:BatchGetItem",
                "dynamodb:DescribeTable",
                "dynamodb:DescribeTimeToLive",
                "dynamodb:GetItem",
                "dynamodb:ListTagsOfResource"
            ],
            tables) +
        valueIfTrue(
            getDynamodbStatement(
                [
                    "dynamodb:ListTables"
                ],
                ""),
            (tables == "*"),
            []
        )]
[/#function]

[#function dynamodbWritePermission tables="*"]
    [#return
        getDynamodbStatement(
            [
                "dynamodb:BatchWriteItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:TagResource",
                "dynamodb:UpdateTimeToLive",
                "dynamodb:UntagResource"
            ],
            tables)]
[/#function]

[#function dynamodbDeletePermission tables="*"]
    [#return
        getDynamodbStatement(
            [
                "dynamodb:DeleteItem"
            ],
            tables)]
[/#function]

[#function dynamodbProducePermission tables="*"]
    [#return
        dynamodbReadPermission(tables) +
        dynamodbWritePermission(tables)]
[/#function]

[#function dynamodbConsumePermission tables="*"]
    [#return
        dynamodbReadPermission(tables) +
        dynamodbDeletePermission(tables)]
[/#function]

[#function dynamodbQueryPermission tables="*" indexes=""]
    [#return
        getDynamodbStatement(
            [
                "dynamodb:Query"
            ],
            tables,
            indexes)]
[/#function]

[#function dynamodbScanPermission tables="*" indexes=""]
    [#return
        getDynamodbStatement(
            [
                "dynamodb:Scan"
            ],
            tables,
            indexes)]
[/#function]

[#function dynamodbManageTablesPermission tables="*"]
    [#return
        getDynamodbStatement(
            [
                "dynamodb:CreateTable",
                "dynamodb:UpdateTable",
                "dynamodb:DeleteTable"
            ],
            tables)]
[/#function]

[#function dynamodbAllPermission tables="*" indexes=""]
    [#return
        dynamodbReadPermission(tables) +
        dynamodbWritePermission(tables) +
        dynamodbDeletePermission(tables) +
        dynamodbQueryPermission(tables, indexes) +
        dynamodbScanPermission(tables, indexes) ]
[/#function]

[#function dynamodbAdminPermission]
    [#return
        dynamodbAllPermission() +
        dynamodbManageTablesPermission() +
        getDynamodbStatement(
            [
                "dynamodb:DescribeLimits",
                "dynamodb:DescribeReservedCapacity",
                "dynamodb:DescribeReservedCapacityOfferings"
            ],
            "")]
    ]
[/#function]
