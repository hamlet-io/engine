[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_deployment ]

    [#-- Validate Deployment Info --]
    [#if getCLODeploymentMode()?has_content ]
        [#if ! getDeploymentMode()?has_content ]
            [@fatal
                message="Undefined deployment mode used"
                detail="Could not find definition of provided DeploymentMode"
                context={ "DeploymentMode" : commandLineOptions.Deployment.Mode }
            /]
        [/#if]
    [/#if]

    [#if getCLODeploymentGroup()?has_content ]
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

            [#if getDeploymentUnitSubset() == "generationcontract"]
                [#assign groupDeploymentUnits = false]
                [#assign ignoreDeploymentUnitSubsetInOutputs = false]

                [#-- We need to initialise the outputs here since we are adding to it out side of the component flow --]
                [@addDefaultGenerationContract subsets=contractSubsets /]
            [/#if]
        [/#if]
    [/#list]

    [@generateOutput
        deploymentFramework=getDeploymentFramework()
        type=getDeploymentOutputType()
        format=getDeploymentOutputFormat()
        level=getDeploymentLevel()
        include=compositeTemplateContent
    /]
[/#macro]

[#-- Add seeder for command line options --]
[#macro shared_entrance_deployment_inputsteps ]

    [@registerInputSeeder
        id=DEPLOYMENT_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToInputPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=DEPLOYMENT_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Adjust the subset if required --]
[#function deployment_inputseeder_commandlineoptions filter state]
    [#local deploymentGroupDetails = getDeploymentGroupDetails(state.CommandLineOptions.Deployment.Group.Name)]

    [#-- ResourceSets  --]
    [#-- Separates resources from their component templates in to their own deployment --]
    [#list ((deploymentGroupDetails.ResourceSets)!{})?values?filter(s -> s.Enabled ) as resourceSet ]
        [#if state.CommandLineOptions.Deployment.Unit.Name == resourceSet["deployment:Unit"] ]

            [#if !((state.CommandLineOptions.Deployment.Unit.Subset)?has_content)]
                [#return
                    mergeObjects(
                        state,
                        {
                            "CommandLineOptions" : {
                                "Deployment" : {
                                    "Unit" : {
                                        "Subset" : state.Deployment.Unit.Name
                                    }
                                }
                            }
                        }
                    )
                ]
            [/#if]
        [/#if]
    [/#list]

    [#return state]

[/#function]

