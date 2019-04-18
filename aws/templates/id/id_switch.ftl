[#-- Switch --]

[#-- Components --]
[#assign SWITCH_COMPONENT_TYPE = "switch" ]
[#assign SWITCH_TOGGLE_COMPONENT_TYPE = "switchtoggle"]

[#assign componentConfiguration +=
    {
        SWITCH_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "A config populated state store"
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
                    "Names" : "StateAttribute",
                    "Description" : "The name of attribute in the table which holds the state of the toggle",
                    "Type" : STRING_TYPE,
                    "Default" : "toggleState"
                },
                {
                    "Names" : "Table",
                    "Children" : dynamoDbTableChildConfiguration
                }
            ],
            "Components" : [
                {
                    "Type" : SWITCH_TOGGLE_COMPONENT_TYPE,
                    "Component" : "Toggles",
                    "Link" : [ "Toggle" ]
                }
            ]
        },
        SWITCH_TOGGLE_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "A state instance in a switch state store"
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
                }
            ]
        }
    }]

[#function getSwitchState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local id = formatResourceId(AWS_DYNAMODB_TABLE_RESOURCE_TYPE, core.Id )]

    [#return
        {
            "Resources" : {
                "table" : {
                    "Id" : id,
                    "Type" : AWS_DYNAMODB_TABLE_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "TABLE_NAME" : getExistingReference(id),
                "TABLE_ARN" : getExistingReference(id, ARN_ATTRIBUTE_TYPE),
                "STATE_ATTRIBUTE" : solution.StateAttribute
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {
                    "default" : "consume",
                    "consume" : [
                        getPolicyStatement(
                            [
                                "dynamodb:BatchGetItem",
                                "dynamodb:DescribeTable",
                                "dynamodb:GetItem",
                                "dynamodb:DescribeTimeToLive",
                                "dynamodb:ListTagsOfResource",
                                "dynamodb:Query"
                                "dynamodb:Scan"
                            ],
                            getExistingReference(id, ARN_ATTRIBUTE_TYPE)
                        )
                    ],
                    "actuate" : [
                        getPolicyStatement(
                            [
                                "dynamodb:BatchGetItem",
                                "dynamodb:DescribeTable",
                                "dynamodb:GetItem",
                                "dynamodb:DescribeTimeToLive",
                                "dynamodb:ListTagsOfResource",
                                "dynamodb:Query",
                                "dynamodb:Scan"
                            ],
                            getExistingReference(id, ARN_ATTRIBUTE_TYPE)
                        ),
                        getPolicyStatement(
                            [
                                "dynamodb:UpdateItem"
                            ],
                            getExistingReference(id, ARN_ATTRIBUTE_TYPE),
                            "",
                            {
                                "ForAllValues:StringEquals": {
                                    "dynamodb:Attributes": [ solution.StateAttribute ]
                                }
                            }
                        )
                    ]
               }
            }
        }
    ]
[/#function]

[#function getSwitchToggleState occurrence ]
    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]

    [#return
        {
            "Resources" : {
                "item" : {
                    "Id" : core.Id,
                    "Name" : core.SubComponent.Name,
                    "Type" : AWS_DYNAMODB_ITEM_RESOURCE_TYPE
                }
            },
            "Attributes" : {
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : { }
            }
        }
    ]
[/#function]