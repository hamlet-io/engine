[#-- Config Store --]

[#-- Components --]
[#assign CONFIGSTORE_COMPONENT_TYPE = "configstore" ]
[#assign CONFIGSTORE_BRANCH_COMPONENT_TYPE = "configbranch"]

[#assign componentConfiguration +=
    {
        CONFIGSTORE_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "A configuration store to provide dynamic attributes"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                }
            ],
            "Attributes" : [
                {
                    "Names" : ["Fragment", "Container"],
                    "Type" : STRING_TYPE,
                    "Default" : ""
                },
                {
                    "Names" : "Table",
                    "Children" : dynamoDbTableChildConfiguration
                },
                {
                    "Names" : "SecondaryKey",
                    "Description" : "Uses the name of the branch to provide a secondary sort key on branches - id being the primary",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                }
            ],
            "Components" : [
                {
                    "Type" : CONFIGSTORE_BRANCH_COMPONENT_TYPE,
                    "Component" : "Branches",
                    "Link" : [ "Branch" ]
                }
            ]
        },
        CONFIGSTORE_BRANCH_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "A branch of configuration which belongs to a config store"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "States",
                    "Descrption" : "A writable attribute in the config branch",
                    "Subobjects" : true,
                    "Children" : [
                        {
                            "Names" : "InitialValue",
                            "Description" : "The initial value that will be applied to the state",
                            "Type" : STRING_TYPE,
                            "Default" : "-"
                        }
                    ]
                }
            ]
        }
    }]

[#macro aws_configstore_cf_state occurrence parent={} baseState={}  ]
    [#assign componentState = getConfigStoreState(occurrence)]
[/#macro]

[#function getConfigStoreState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local id = formatResourceId(AWS_DYNAMODB_TABLE_RESOURCE_TYPE, core.Id )]
    [#local key = "branch" ]

    [#local sortKey = "" ]
    [#if solution.SecondaryKey ]
        [#local sortKey = "instance" ]
    [/#if]

    [#return
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
[/#function]

[#macro aws_configbranch_cf_state occurrence parent={} baseState={}  ]
    [#assign componentState = getConfigBranchState(occurrence, parent)]
[/#macro]

[#function getConfigBranchState occurrence parent ]
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

    [#return
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
[/#function]