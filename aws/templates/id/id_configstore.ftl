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

[#function getConfigStoreState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local id = formatResourceId(AWS_DYNAMODB_TABLE_RESOURCE_TYPE, core.Id )]
    [#local key = "branch" ]

    [#return
        {
            "Resources" : {
                "table" : {
                    "Id" : id,
                    "Key" : key,
                    "Type" : AWS_DYNAMODB_TABLE_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "TABLE_NAME" : getExistingReference(id),
                "TABLE_ARN" : getExistingReference(id, ARN_ATTRIBUTE_TYPE),
                "TABLE_KEY" : key
            },
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

[#function getConfigBranchState occurrence parent ]
    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]

    [#local parentStateAttributes = parent.State.Attributes ]
    [#local parentResources = parent.State.Resources]

    [#local tableId = parentResources["table"].Id ]
    [#local tableArn = parentStateAttributes["TABLE_ARN"]]
    [#local tableKey = parentStateAttributes["TABLE_KEY"]]

    [#local branchName = core.SubComponent.Name ]

    [#local states = [] ]
    [#local stateManagementPolicy = []]
    [#list solution.States as id,state ]
        [#local states += [ state.Name ] ]
    [/#list]

    [#return
        {
            "Resources" : {
                "item" : {
                    "Id" : core.Id,
                    "Name" : branchName,
                    "Type" : AWS_DYNAMODB_ITEM_RESOURCE_TYPE
                },
                "table" : parentResources["table"]
            },
            "Attributes" : {
                "KEY_VALUE" : branchName,
                "STATE_KEYS" : states?join(",")
            } + 
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
                            branchName
                         )),
                    "managestate" :
                        dynamoDbViewerPermission(
                            getReference(tableId, ARN_ATTRIBUTE_TYPE), 
                            [], 
                            "",
                            getDynamoDbItemCondition(
                                branchName
                            )
                        ) + 
                        valueIfContent(
                            dynamoDbUpdatePermission(
                                getReference(tableId, ARN_ATTRIBUTE_TYPE), 
                                "",
                                getDynamoDbItemCondition(
                                    branchName,
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