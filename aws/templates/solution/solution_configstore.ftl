[#-- Config Store --]

[#if componentType == CONFIGSTORE_COMPONENT_TYPE ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign parentCore = occurrence.Core]
        [#assign parentSolution = occurrence.Configuration.Solution]
        [#assign parentResources = occurrence.State.Resources]

        [#assign tableId = parentResources["table"].Id ]
        [#assign tableKey = parentResources["table"].Key ]
        [#assign tableSortKey = parentResources["table"].SortKey!"" ]

        [#assign itemInitCommand = "initItem"]
        [#assign itemUpdateCommand = "updateItem" ]
        [#assign tableCleanupCommand = "cleanupTable" ]

        [#assign dynamoTableKeys = getDynamoDbTableKey(tableKey , "hash")]
        [#assign dynamoTableKeyAttributes = getDynamoDbTableAttribute( tableKey, STRING_TYPE)]

        [#if parentSolution.SecondaryKey ]
            [#assign dynamoTableKeys += getDynamoDbTableKey(tableSortKey, "range" )]
            [#assign dynamoTableKeyAttributes += getDynamoDbTableAttribute(tableSortKey, STRING_TYPE)]
        [/#if]

        [#assign runIdAttributeName = "runId" ]
        [#assign runIdAttribute = getDynamoDbTableItem( ":run_id", runId)]

        [#assign fragment =
                contentIfContent(parentSolution.Fragment, getComponentId(parentCore.Component)) ]

        [#assign _parentContext =
            {
                "Id" : fragment,
                "Name" : fragment,
                "Instance" : parentCore.Instance.Id,
                "Version" : parentCore.Version.Id
            }
        ]
        [#assign fragmentId = formatFragmentId(_parentContext)]

        [#-- Lookup table name once it has been deployed --]
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

        [#-- Branch setup --]
        [#list occurrence.Occurrences![] as subOccurrence]

            [#assign core = subOccurrence.Core ]
            [#assign solution = subOccurrence.Configuration.Solution ]
            [#assign resources = subOccurrence.State.Resources ]

            [#assign itemId = resources["item"].Id]
            [#assign itemPrimaryKey = resources["item"].PrimaryKey ]
            [#assign itemSecondaryKey = (resources["item"].SecondaryKey)!"" ]

            [#assign initCliId = formatId( itemId, "init")]
            [#assign updateCliId = formatId( itemId, "update" )]

            [#assign contextLinks = getLinkTargets(subOccurrence)]

            [#assign _context =
                {
                    "Id" : fragment,
                    "Name" : fragment,
                    "Instance" : parentCore.Instance.Id,
                    "Version" : parentCore.Version.Id,
                    "Environment" : {},
                    "Links" : contextLinks,
                    "DefaultEnvironment" : defaultEnvironment(subOccurrence, contextLinks),
                    "DefaultCoreVariables" : false,
                    "DefaultEnvironmentVariables" : false,
                    "DefaultLinkVariables" : true,
                    "Branch" : formatName(itemPrimaryKey + itemSecondaryKey) 
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
                                        "configStore" : parentCore.Id
                                    } +
                                    (_context.Environment!{})

                }
            ]

            [#if deploymentSubsetRequired("cli", false) ]

                [#assign branchItemKey = getDynamoDbTableItem( tableKey, itemPrimaryKey )]

                [#if parentSolution.SecondaryKey ]
                    [#assign branchItemKey = mergeObjects(branchItemKey, getDynamoDbTableItem( tableSortKey, itemSecondaryKey) ) ]
                [/#if]

                [#assign branchUpdateAttribtueValues = runIdAttribute ]
                [#assign branchUpdateExpression =
                    [
                        runIdAttributeName + " = :run_id"
                    ]
                ]

                [#list solution.States as id,state ]
                    [#assign branchUpdateAttribtueValues += getDynamoDbTableItem( ":" + state.Name, state.InitialValue )]
                    [#assign branchUpdateExpression += [ state.Name + " = if_not_exists(" + state.Name + ", :" + state.Name + ")" ]]
                [/#list]

                [#list _context.Environment as envKey, envValue ]
                    [#if envValue?has_content ]
                        [#assign branchUpdateAttribtueValues += getDynamoDbTableItem( ":" + envKey, envValue )]
                        [#assign branchUpdateExpression += [ envKey + " = :" + envKey ]]
                    [/#if]
                [/#list]

                [@cfCli
                    id=updateCliId
                    mode=listMode
                    command=itemUpdateCommand
                    content={
                        "Key" : branchItemKey
                    } +
                    attributeIfContent(
                        "UpdateExpression",
                        branchUpdateExpression,
                        "SET " + branchUpdateExpression?join(", ")
                    ) +
                    attributeIfContent(
                        "ExpressionAttributeValues",
                        branchUpdateAttribtueValues
                    )
                /]
            [/#if]


            [#if deploymentSubsetRequired("epilogue", false)]
                [@cfScript
                    mode=listMode
                    content=[
                        " case $\{STACK_OPERATION} in",
                        "   create|update)",
                        "       # Manage Branch Attributes",
                        "       info \"Creating DynamoDB Item - Table: " + tableId + " - Primary Key: " + itemPrimaryKey + " - Secondary Key: " + itemSecondaryKey "\"",
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

            [#assign projectionExpression = [ "#" + tableKey]  ]
            [#assign expressionAttributeNames = { "#" + tableKey : tableKey } ]

            [#if parentSolution.SecondaryKey ]
                [#assign projectionExpression += [ "#" + tableSortKey ] ]
                [#assign expressionAttributeNames += { "#" + tableSortKey : tableSortKey } ]
            [/#if]

            [@cfCli
                mode=listMode
                id=tableId
                command=tableCleanupCommand
                content={
                    "FilterExpression" : cleanupFilterExpression,
                    "ExpressionAttributeValues" : cleanupExpressionAttributeValues,
                    "ProjectionExpression" : projectionExpression?join(", "),
                    "ExpressionAttributeNames" : expressionAttributeNames
                }
            /]
        [/#if]

        [#if deploymentSubsetRequired("epilogue", false)]
            [@cfScript
                mode=listMode
                content=[
                    " case $\{STACK_OPERATION} in",
                    "   create|update)",
                    "       # Clean up old branch items",
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

        [#if deploymentSubsetRequired(CONFIGSTORE_COMPONENT_TYPE, true) ]
            [@createDynamoDbTable
                id=tableId
                mode=listMode
                backupEnabled=parentSolution.Table.Backup.Enabled
                billingMode=parentSolution.Table.Billing
                writeCapacity=parentSolution.Table.Capacity.Write
                readCapacity=parentSolution.Table.Capacity.Read
                attributes=dynamoTableKeyAttributes
                keys=dynamoTableKeys
            /]
        [/#if]
    [/#list]
[/#if]
