[#ftl]

[#-- Deployment frameworks --]
[#assign DEFAULT_DEPLOYMENT_FRAMEWORK = "default"]

[#-- Management Contracts --]
[#macro createManagementContractStage
        deploymentUnit
        deploymentPriority
        deploymentGroup
        deploymentProvider
        currentState
        deploymentMode=getDeploymentMode()
    ]

    [#local deploymentModeDetails = getDeploymentModeDetails(deploymentMode)]
    [#local deploymentGroupDetails = getDeploymentGroupDetails(deploymentGroup) ]

    [#if deploymentModeDetails?has_content ]
        [#local executionPolicy = deploymentModeDetails.ExecutionPolicy ]

        [#local mandatoryContract = false]
        [#switch executionPolicy ]
            [#case "Required" ]
                [#local mandatoryContract = true ]
                [#break]

            [#case "Optional" ]
                [#local mandatoryContract = false ]
                [#break]
        [/#switch]

        [#if deploymentGroupDetails?has_content ]

            [#local stageId = "${deploymentGroupDetails.Id}_${deploymentModeDetails.Id}" ]
            [#local stagePriority = 0 ]
            [#local stageEnabled = false ]

            [#-- Determine the group order --]
            [#switch deploymentModeDetails.Membership ]
                [#case "explicit" ]
                    [#local groupList = (deploymentModeDetails.Explicit.Groups)![] ]
                    [#if groupList?seq_contains(deploymentGroupDetails.Name) ]
                        [#local stageEnabled = true]
                        [#local stagePriority = groupList?seq_index_of(deploymentGroupDetails.Name) + 1 ]
                    [/#if]
                    [#break]

                [#case "priority" ]
                    [#if deploymentGroupDetails.Name?matches( deploymentModeDetails.Priority.GroupFilter ) ]
                        [#local stageEnabled = true]
                        [#local stagePriority = valueIfTrue(
                                                    deploymentGroupDetails.Priority,
                                                    (deploymentModeDetails.Priority.Order == "LowestFirst"),
                                                    1000 - deploymentGroupDetails.Priority
                                                )]
                    [/#if]
                    [#break]

                [#case "orphaned"]
                    [#if deploymentGroupDetails.Name?matches( deploymentModeDetails.Priority.GroupFilter ) ]
                        [#local stageEnabled = true]
                        [#-- Make the priority as low as possible while still maintaining the group order --]
                        [#-- This ensures that orphaned components are cleaned up in order to reduce dependencies --]
                        [#local stagePriority = deploymentGroupDetails.Priority * 0.1 ]
                    [/#if]
                    [#break]

            [/#switch]

            [#if stageEnabled ]
                [@contractStage
                    id=stageId
                    executionMode=CONTRACT_EXECUTION_MODE_PRIORITY
                    priority=stagePriority
                    mandatory=mandatoryContract
                /]

                [#local stepPriority = valueIfTrue(
                    deploymentPriority,
                    (deploymentModeDetails.Priority.Order == "LowestFirst"),
                    1000 - deploymentPriority
                )]]

                [@contractStep
                    id=formatId(stageId, deploymentUnit)
                    stageId=stageId
                    taskType=MANAGE_DEPLOYMENT_TASK_TYPE
                    priority=stepPriority
                    mandatory=mandatoryContract
                    parameters=
                        {
                            "DeploymentUnit" : deploymentUnit,
                            "DeploymentGroup" : deploymentGroupDetails.Name,
                            "DeploymentProvider" : deploymentProvider,
                            "District" : deploymentGroupDetails.District,
                            "Operations" : deploymentModeDetails.Operations,
                            "CurrentState" : currentState
                        }
                /]
            [/#if]
        [/#if]
    [/#if]
[/#macro]

[#macro createOccurrenceManagementContractStep occurrence ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resourceGroups = occurrence.State.ResourceGroups ]

    [#if ((solution["deployment:Group"])!"")?has_content ]

        [@addOccurrenceDeploymentState
            occurrence=occurrence
        /]

        [#local deploymentUnit = getOccurrenceDeploymentUnit(occurrence) ]
        [#local deploymentGroup = solution["deployment:Group"]]

        [@createManagementContractStage
            deploymentUnit=deploymentUnit
            deploymentGroup=deploymentGroup
            deploymentPriority=solution["deployment:Priority"]
            deploymentProvider=resourceGroups["default"].Placement.Provider
            currentState=getDeploymentUnitStates(deploymentGroup, deploymentUnit)
                            ?seq_contains(true)?then("deployed", "notdeployed")
        /]
    [/#if]
[/#macro]

[#macro createResourceSetManagementContractStep deploymentGroup deploymentUnit currentState priority="" deploymentMode=getDeploymentMode() ]
    [#local deploymentGroupDetails = getDeploymentGroupDetails(deploymentGroup)]

    [#list ((deploymentGroupDetails.ResourceSets)!{})?values?filter(s -> s.Enabled && s["deployment:Unit"] == deploymentUnit ) as resourceSet ]
        [@createManagementContractStage
            deploymentUnit=resourceSet["deployment:Unit"]
            deploymentGroup=deploymentGroupDetails.Name
            deploymentPriority=priority?has_content?then(priority, resourceSet["deployment:Priority"])
            deploymentProvider=getLoaderProviders()[0]
            currentState=currentState
            deploymentMode=deploymentMode
        /]
    [/#list]
[/#macro]
