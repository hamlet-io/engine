[#-- State Switch --]

[#if componentType == SWITCH_COMPONENT_TYPE ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign parentCore = occurrence.Core]
        [#assign parentSolution = occurrence.Configuration.Solution]
        [#assign parentResources = occurrence.State.Resources]

        [#assign tableId = parentResources["table"].Id ]

        [#assign itemInitCommand = "initItem"]
        [#assign itemUpdateCommand = "updateItem" ]
        [#assign tableCleanupCommand = "cleanupTable" ]

        [#assign dynamoTableKeys = getDynamoDbTableKey("toggle" , "hash")]
        [#assign dynamoTableAttributes = getDynamoDbTableAttribute( "toggle", STRING_TYPE)]

        [#assign runIdAttributeName = "runId" ]
        [#assign runIdAttribute = getDynamoDbTableItem( ":run_id", runId)]
        
        [#assign toggleStateAttributeName = parentSolution.StateAttribute ]
        [#assign toggleStateAttribute = getDynamoDbTableItem( ":toggle_state", "-")]
        
        [#assign fragment =
                contentIfContent(parentSolution.Fragment, getComponentId(parentCore.Component)) ]

        [#assign contextLinks = getLinkTargets(occurrence)]
        [#assign _context =
            {
                "Id" : fragment,
                "Name" : fragment,
                "Instance" : parentCore.Instance.Id,
                "Version" : parentCore.Version.Id,
                "Environment" : {}
            }
        ]
        
        [#assign fragmentId = formatFragmentId(_context)]
        [#assign containerId = fragmentId]


        [#if deploymentSubsetRequired("epilogue", false)]
            [@cfScript 
                mode=listMode
                content=[
                    " case $\{STACK_OPERATION} in",
                    "   create|update)",
                    "       # Get cli config file",
                    "       split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?", 
                    "       # Get DynamoDb TableName",
                    "       export tableName=$(get_cloudformation_stack_output" +
                    "       \"" + region + "\" " + 
                    "       \"$\{STACK_NAME}\" " +
                    "       \"" + tableId + "\" " +
                    "       || return $?)",
                    "       ;;",
                    " esac"
                ]
            /]
        [/#if]

        [#list occurrence.Occurrences![] as subOccurrence]

            [#assign core = subOccurrence.Core ]
            [#assign solution = subOccurrence.Configuration.Solution ]
            [#assign resources = subOccurrence.State.Resources ]

            [#assign itemId = resources["item"].Id]
            [#assign itemName = resources["item"].Name]

            [#assign initCliId = formatId( itemId, "init")]
            [#assign updateCliId = formatId( itemId, "update" )]

            [#assign contextLinks = getLinkTargets(subOccurrence)]

            [#assign _context += 
                {
                    "Links" : contextLinks,
                    "DefaultEnvironment" : defaultEnvironment(subOccurrence, contextLinks),
                    "DefaultCoreVariables" : false,
                    "DefaultEnvironmentVariables" : false,
                    "DefaultLinkVariables" : true,
                    "Toggle" : itemName
                }
            ]

            [#-- Add in fragment specifics including override of defaults --]
            [#assign fragmentListMode = "model"]
            [#include fragmentList?ensure_starts_with("/")]

            [#assign finalEnvironment = getFinalEnvironment(subOccurrence, _context ) ]
            [#assign _context += finalEnvironment ]

            [#assign _context +=
                {
                    "Environment" : { 
                                        "switch" : parentCore.Id
                                    } + 
                                    (_context.Environment!{}) 

                }
            ]


            [#if deploymentSubsetRequired("cli", false) ]

                [#assign toggleItemKey = getDynamoDbTableItem( "toggle", itemName )]

                [#assign toggleUpdateAttribtueValues = runIdAttribute + toggleStateAttribute ]
                [#assign toggleUpdateExpression = 
                    [ 
                        toggleStateAttributeName + " = if_not_exists(" + toggleStateAttributeName + ", :toggle_state)",
                        runIdAttributeName + " = :run_id" 
                    ]
                ]

                [#list _context.Environment as envKey, envValue ]
                    [#assign envKey = envKey]
                    [#if envValue?has_content ]
                        [#assign toggleUpdateAttribtueValues += getDynamoDbTableItem( ":" + envKey, envValue )]
                        [#assign toggleUpdateExpression += [ envKey + " = :" + envKey ]]
                    [/#if]
                [/#list]

                [@cfCli 
                    id=updateCliId
                    mode=listMode
                    command=itemUpdateCommand
                    content={
                        "Key" : toggleItemKey
                    } + 
                    attributeIfContent(
                        "UpdateExpression",
                        toggleUpdateExpression,
                        "SET " + toggleUpdateExpression?join(", ")
                    ) +
                    attributeIfContent(
                        "ExpressionAttributeValues",
                        toggleUpdateAttribtueValues
                    )
                /]   
            [/#if]   


            [#if deploymentSubsetRequired("epilogue", false)]
                [@cfScript 
                    mode=listMode
                    content=[
                        " case $\{STACK_OPERATION} in",
                        "   create|update)",
                        "       # Manage Toggle Attributes",
                        "       info \"Creating DynamoDB Item - Table: " + tableId + " - Item: " + itemName + "\"",
                        "       upsert_dynamodb_item" +
                        "       \"" + region + "\" " + 
                        "       \"$\{tableName}\" " +
                        "       \"$\{tmpdir}/cli-" + updateCliId + "-" + itemUpdateCommand + ".json\" " +
                        "       \"$\{STACK_NAME}\" " +
                        "       || return $?",
                        "       ;;",
                        " esac"
                    ]
                /]   
            [/#if] 
        [/#list]

        [#-- cleanup old items --]
        [#if deploymentSubsetRequired("cli", false) ]
            [#assign cleanupFilterExpression = "NOT " + runIdAttributeName + " = :run_id"  ]
            [#assign cleanupExpressionAttributeValues = runIdAttribute ]

            [@cfCli 
                mode=listMode
                id=tableId 
                command=tableCleanupCommand
                content={
                    "FilterExpression" : cleanupFilterExpression,
                    "ExpressionAttributeValues" : cleanupExpressionAttributeValues,
                    "ProjectionExpression" : "#toggle",
                    "ExpressionAttributeNames" : {
                        "#toggle" : "toggle"
                    }
                }
            /]
        [/#if]


        [#if deploymentSubsetRequired("epilogue", false)]
            [@cfScript 
                mode=listMode
                content=[
                    " case $\{STACK_OPERATION} in",
                    "   create|update)",
                    "       # Clean up old toggle items",
                    "       info \"Cleaning up old items DynamoDB - Table: " + tableId + "\"",
                    "       old_items=$(scan_dynamodb_table" +
                    "       \"" + region + "\" " + 
                    "       \"$\{tableName}\" " +
                    "       \"$\{tmpdir}/cli-" + tableId + "-" + tableCleanupCommand + ".json\" " +
                    "       \"$\{STACK_NAME}\" " +
                    "       || return $?)",
                    "       delete_dynamodb_items" +
                    "       \"" + region + "\" " + 
                    "       \"$\{tableName}\" " +
                    "       \"$\{old_items}\" " +
                    "       \"$\{STACK_NAME}\" " +
                    "       || return $?",
                    "       ;;",
                    " esac"
                    ]
            /]
        [/#if]

        [#if deploymentSubsetRequired(SWITCH_COMPONENT_TYPE, true) ]
            [@createDynamoDbTable 
                id=tableId
                mode=listMode
                backupEnabled=parentSolution.Table.Backup.Enabled
                billingMode=parentSolution.Table.Billing
                writeCapacity=parentSolution.Table.Capacity.Write
                readCapacity=parentSolution.Table.Capacity.Read 
                attributes=dynamoTableAttributes
                keys=dynamoTableKeys
            /]
        [/#if]
    [/#list]
[/#if]
