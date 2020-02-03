[#ftl]

[#macro aws_configstore_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local id = formatResourceId(AWS_DYNAMODB_TABLE_RESOURCE_TYPE, core.Id )]
    [#local key = "branch" ]

    [#local sortKey = "" ]
    [#if solution.SecondaryKey ]
        [#local sortKey = "instance" ]
    [/#if]

    [#assign componentState =
        {
            "Resources" : {
                "table" : {
                    "Id" : id,
                    "Key" : key,
                    "SortKey" : sortKey,
                    "Type" : AWS_DYNAMODB_TABLE_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "TABLE_NAME" : getExistingReference(id),
                "TABLE_ARN" : getExistingReference(id, ARN_ATTRIBUTE_TYPE),
                "TABLE_KEY" : key
            } +
            attributeIfContent(
                "TABLE_SORT_KEY",
                sortKey
            ),
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {
                    "default" : "consume",
                    "consume" : dynamoDbViewerPermission(
                                    getReference(id, ARN_ATTRIBUTE_TYPE)
                                )
               }
            }
        }
    ]
[/#macro]

[#macro aws_configbranch_cf_state occurrence parent={} ]
    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]

    [#local parentSolution = parent.Configuration.Solution ]
    [#local parentStateAttributes = parent.State.Attributes ]
    [#local parentResources = parent.State.Resources]

    [#local itemId = core.Id ]
    [#if parentSolution.SecondaryKey ]
        [#local itemId = formatId(core.Id, core.SubComponent.Name)]
    [/#if]

    [#local tableId = parentResources["table"].Id ]
    [#local tableArn = parentStateAttributes["TABLE_ARN"]]
    [#local tableKey = parentStateAttributes["TABLE_KEY"]]

    [#local primaryKeyValue = core.SubComponent.Id ]
    [#local secondaryKeyValue = core.SubComponent.Name]

    [#local states = [] ]
    [#local stateManagementPolicy = []]
    [#list solution.States as id,state ]
        [#local states += [ state.Name ] ]
    [/#list]

    [#assign componentState =
        {
            "Resources" : {
                "item" : {
                    "Id" : itemId,
                    "PrimaryKey" : primaryKeyValue,
                    "Type" : AWS_DYNAMODB_ITEM_RESOURCE_TYPE
                } +
                attributeIfTrue(
                    "SecondaryKey"
                    parentSolution.SecondaryKey,
                    secondaryKeyValue
                ),
                "table" : parentResources["table"]
            },
            "Attributes" : {
                "PRIMARY_KEY_VALUE" : primaryKeyValue,
                "STATE_KEYS" : states?join(",")
            } +
            attributeIfTrue(
                "SECONDARY_KEY_VALUE",
                parentSolution.SecondaryKey,
                secondaryKeyValue
            ) +
            parentStateAttributes,
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {
                    "default" : "consume",
                    "consume" : dynamoDbViewerPermission(
                        getReference(tableId, ARN_ATTRIBUTE_TYPE),
                        [],
                        "",
                        getDynamoDbItemCondition(
                            primaryKeyValue
                         )),
                    "managestate" :
                        dynamoDbViewerPermission(
                            getReference(tableId, ARN_ATTRIBUTE_TYPE),
                            [],
                            "",
                            getDynamoDbItemCondition(
                                primaryKeyValue
                            )
                        ) +
                        valueIfContent(
                            dynamoDbUpdatePermission(
                                getReference(tableId, ARN_ATTRIBUTE_TYPE),
                                "",
                                getDynamoDbItemCondition(
                                    primaryKeyValue,
                                    states
                                ))
                            states,
                            []
                        )
                }
            }
        }
    ]
[/#macro]