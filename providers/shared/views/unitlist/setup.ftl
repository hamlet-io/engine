[#ftl]

[#macro shared_view_unitlist_managementcontract ]

    [#-- Look through all stack outputs to determine all of the possible deployments that exisit --]
    [#-- Stack outputs not part of the deployment state are considered orphaned --]
    [#-- Using this state we then create a contract step using the _orphan deployment mode to decide what to do --]
    [#list stackOutputsList as stackOutput ]

        [#local deploymentUnit = stackOutput.DeploymentUnit ]

        [#local deploymentGroups = []]
        [#if ((stackOutput.Level)!"")?has_content ]
            [#local deploymentGroups = getDeploymentGroupFromOutputLevel(stackOutput.Level) ]
        [#else]
            [#local deploymentGroups = getDeploymentGroupsFromState() ]
        [/#if]

        [#list deploymentGroups as deploymentGroup ]
            [#local groupDetails = getDeploymentGroupDetails(deploymentGroup)]

            [#if (groupDetails.ResourceSets!{})?keys?seq_contains(deploymentUnit) ]

                [@addDeploymentState
                    deploymentGroup=deploymentGroup
                    deploymentUnit=deploymentUnit
                    deployed=true
                /]

                [#-- Orphan Resource sets which have been disabled but are deployed exist --]
                [#if ! (groupDetails.ResourceSets[deploymentUnit].Enabled) ]

                    [@createResourceSetManagementContractStep
                        deploymentGroup=deploymentGroup
                        deploymentUnit=deploymentUnit
                        currentState="orphaned"
                        priority=999
                        deploymentMode="_orphan"
                    /]

                [/#if]

            [/#if]

            [#-- Fiters out edge cases --]
            [#-- - Account units - We don't know the resources which belong to an account to say if its suppose to be deployed or not --]
            [#-- - Resource Sets - We don't know the resources which belong to a resource set to say if its suppose to be deployed or not --]
            [#-- - psuedo stack outputs - They use the unit to show that the stackoutput is different --]
            [#if ! ((groupDetails.CompositeTemplate)!"")?has_content
                    && ! (groupDetails.ResourceSets!{})?keys?seq_contains(deploymentUnit)
                    && ! deploymentUnit?ends_with("-epilogue")
                    && ! deploymentUnit?ends_with("-prologue")
                    && deploymentUnit?has_content ]

                [#local deployState = getDeploymentUnitStates(deploymentGroup, deploymentUnit ) ]

                [#if ! deployState?has_content ]
                    [@createManagementContractStage
                        deploymentUnit=deploymentUnit
                        deploymentPriority=999
                        deploymentGroup=deploymentGroup
                        deploymentProvider=(getCLODeploymentProviders()[0])!SHARED_PROVIDER
                        currentState="orphaned"
                        deploymentMode="_orphan"
                    /]
                [/#if]
            [/#if]
        [/#list]
    [/#list]

    [#-- Add all of the required Resource Sets - Set deployed state to false --]
    [#if getOutputContent("stages")?has_content ]
        [#list getOutputContent("stages")?keys as deploymentGroup ]
            [#local groupDetails = getDeploymentGroupDetails(deploymentGroup)]

            [#list (groupDetails.ResourceSets)?values as resourceSet ]

                [#local deploymentUnit = resourceSet["deployment:Unit"] ]

                [@createResourceSetManagementContractStep
                    deploymentGroup=deploymentGroup
                    deploymentUnit=deploymentUnit
                    currentState=getDeploymentUnitStates(deploymentGroup, deploymentUnit)
                                    ?seq_contains(true)?then("deployed", "notdeployed")
                /]
            [/#list]
        [/#list]
    [/#if]

[/#macro]
