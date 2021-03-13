[#ftl]

[#-- Deployment frameworks --]
[#assign DEFAULT_DEPLOYMENT_FRAMEWORK = "default"]

[#-- Management Contracts --]
[#macro createManagementContractStage deploymentUnit deploymentPriority deploymentGroup deploymentProvider deploymentMode=getDeploymentMode() ]

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

            [#local stageId = deploymentGroupDetails.Id ]
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
                            "Operations" : deploymentModeDetails.Operations
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
        [@createManagementContractStage
            deploymentUnit=getOccurrenceDeploymentUnit(occurrence)
            deploymentGroup=solution["deployment:Group"]
            deploymentPriority=solution["deployment:Priority"]
            deploymentProvider=resourceGroups["default"].Placement.Provider
        /]
    [/#if]
[/#macro]

[#macro createResourceSetManagementContractStep deploymentGroupDetails ]
    [#list ((deploymentGroupDetails.ResourceSets)!{})?values?filter(s -> s.Enabled ) as resourceSet ]
        [@createManagementContractStage
            deploymentUnit=resourceSet["deployment:Unit"]
            deploymentGroup=deploymentGroupDetails.Name
            deploymentPriority=resourceSet["deployment:Priority"]
            deploymentProvider=(commandLineOptions.Deployment.Provider.Names)[0]
        /]
    [/#list]
[/#macro]
