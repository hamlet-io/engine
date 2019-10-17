[#ftl]

[#assign DYNAMODB_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "Attribute" : "Arn"
        },
        EVENTSTREAM_ATTRIBUTE_TYPE : {
            "Attribute" : "StreamArn"
        }
    }
]

[@addOutputMapping 
    provider=AWS_PROVIDER
    resourceType=AWS_DYNAMODB_TABLE_RESOURCE_TYPE
    mappings=DYNAMODB_OUTPUT_MAPPINGS
/]

[#assign metricAttributes +=
    {
        AWS_DYNAMODB_TABLE_RESOURCE_TYPE : {
            "Namespace" : "AWS/DynamoDB",
            "Dimensions" : {
                "TableName" : {
                    "Output" : ""
                }
            }
        }
    }
]

[#function getDynamoDbAttributeType type ]
    [#switch type?upper_case ]
        [#case STRING_TYPE?upper_case ]
        [#case "S" ]
            [#return "S" ]
            [#break]

        [#case NUMBER_TYPE?upper_case ]
        [#case "N"]
            [#return "N" ]
            [#break]

        [#case "BINARY" ]
        [#case "B" ]
            [#return  "B" ]
            [#break]

        [#default]
            [#return "" ]
            [@fatal
                message="Invalid Attribute type"
                context={ "Name" : name, "Type" : type }
            /]
    [/#switch]
[/#function]


[#function getDynamoDbTableAttribute name type ]
    [#return
        [
            {
                "AttributeName" : name,
                "AttributeType" : getDynamoDbAttributeType(type)
            }
        ]
    ]
[/#function]

[#function getDynamoDbTableKey name type ]
    [#local type = type?upper_case ]
    [#switch type ]
        [#case "HASH" ]
        [#case "RANGE" ]
            [#break]

        [#default]
            [@fatal
                message="Invalid Key type"
                context={ "Name" : name, "Type" : type }
            /]
    [/#switch]

    [#return
        [
            {
                "AttributeName" : name,
                "KeyType" : type
            }
        ]
    ]
[/#function]

[#function getDynamoDbTableItem name value type=STRING_TYPE ]
    [#return
        {
            name : {
                getDynamoDbAttributeType(type) : value
            }
        }
    ]
[/#function]

[#macro createDynamoDbTable id
        backupEnabled
        billingMode
        attributes
        keys
        name=""
        streamEnabled=false
        streamViewType=""
        writeCapacity=1
        readCapacity=1
]

    [#switch billingMode?lower_case ]
        [#case "provisioned" ]
            [#local billingMode = "PROVISIONED" ]
            [#break]
        [#case "per-request" ]
            [#local billingMode = "PAY_PER_REQUEST" ]
            [#break]
        [#default]
    [/#switch]

    [@cfResource
        id=id
        type="AWS::DynamoDB::Table"
        properties=
            {
                "AttributeDefinitions" : asArray(attributes),
                "BillingMode" : billingMode,
                "KeySchema" : asArray(keys),
                "Tags" : getCfTemplateCoreTags(name)
            } +
            attributeIfTrue(
                "PointInTimeRecoverySpecification",
                backupEnabled,
                {
                    "PointInTimeRecoveryEnabled" : true
                }
            ) +
            attributeIfTrue(
                "ProvisionedThroughput",
                billingMode == "PROVISIONED",
                {
                    "ReadCapacityUnits" : readCapacity,
                    "WriteCapacityUnits" : writeCapacity
                }
            ) +
            attributeIfTrue(
                "StreamSpecification",
                streamEnabled,
                {
                    "StreamViewType" : streamViewType
                }
            )
        outputs=DYNAMODB_OUTPUT_MAPPINGS +
                    attributeIfTrue(
                        EVENTSTREAM_ATTRIBUTE_TYPE,
                        !streamEnabled,
                        {
                            "Value" : "not-available"
                        }
                    )
    /]
[/#macro]