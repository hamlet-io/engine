[#ftl]

[#macro shared_entrance_deployment ]

    [#-- Validate Deployment Info --]
    [#if ((commandLineOptions.Deployment.Mode)!"")?has_content ]
        [#if ! getDeploymentMode()?has_content ]
            [@fatal
                message="Undefined deployment mode used"
                detail="Could not find definition of provided DeploymentMode"
                context={ "DeploymentMode" : commandLineOptions.Deployment.Mode }
            /]
        [/#if]
    [/#if]

    [#if ((commandLineOptions.Deployment.Group.Name)!"")?has_content ]
        [#if ! getDeploymentGroup()?has_content ]
            [@fatal
                message="Undefined deployment group used"
                detail="Could not find definition of provided DeploymentGroup"
                context={ "DeploymentGroup" : commandLineOptions.Deployment.Group.Name }
            /]
        [/#if]
    [/#if]

    [#assign deploymentGroupDetails = getDeploymentGroupDetails(getDeploymentGroup())]
    [#assign compositeTemplateContent = (.vars[deploymentGroupDetails.CompositeTemplate])!"" ]

    [#-- ResourceSets  --]
    [#-- Seperates resources from their component templates in to their own deployment --]
    [#list ((deploymentGroupDetails.ResourceSets)!{})?values?filter(s -> s.Enabled ) as resourceSet ]
        [#if getDeploymentUnit() == resourceSet["deployment:Unit"] ]

            [#assign groupDeploymentUnits = true]
            [#assign ignoreDeploymentUnitSubsetInOutputs = true]

            [#assign contractSubsets = []]
            [#list resourceSet.ResourceLabels as label ]
                [#assign resourceLabel = getResourceLabel(label, getDeploymentLevel()) ]
                [#assign contractSubsets = combineEntities( contractSubsets, (resourceLabel.Subsets)![], UNIQUE_COMBINE_BEHAVIOUR ) ]
            [/#list]

            [#if (commandLineOptions.Deployment.Unit.Subset!"") == "generationcontract"]
                [#assign groupDeploymentUnits = false]
                [#assign ignoreDeploymentUnitSubsetInOutputs = false]

                [#-- We need to initialise the outputs here since we are adding to it out side of the component flow --]
                [@addDefaultGenerationContract subsets=contractSubsets /]

            [#else]
                [#if !(commandLineOptions.Deployment.Unit.Subset?has_content)]
                    [#assign commandLineOptions =
                        mergeObjects(
                            commandLineOptions,
                            {
                                "Deployment" : {
                                    "Unit" : {
                                        "Subset" : getDeploymentUnit()
                                    }
                                }
                            }
                        ) ]
                [/#if]
            [/#if]
        [/#if]
    [/#list]

    [@generateOutput
        deploymentFramework=commandLineOptions.Deployment.Framework.Name
        type=commandLineOptions.Deployment.Output.Type
        format=commandLineOptions.Deployment.Output.Format
        level=getDeploymentLevel()
        include=compositeTemplateContent
    /]
[/#macro]
