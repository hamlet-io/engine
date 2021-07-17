[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_deployment ]

    [#-- Validate Deployment Info --]
    [#if getCLODeploymentMode()?has_content ]
        [#if ! getDeploymentMode()?has_content ]
            [@fatal
                message="Undefined deployment mode used"
                detail="Could not find definition of provided DeploymentMode"
                context={ "DeploymentMode" : getCLODeploymentMode() }
            /]
        [/#if]
    [/#if]

    [#if getCLODeploymentGroup()?has_content ]
        [#if ! getDeploymentGroup()?has_content ]
            [@fatal
                message="Undefined deployment group used"
                detail="Could not find definition of provided DeploymentGroup"
                context={ "DeploymentGroup" : getCLODeploymentGroup() }
            /]
        [/#if]
    [/#if]

    [#local deploymentGroupDetails = getDeploymentGroupDetails(getDeploymentGroup())]

    [#-- ResourceSets  --]
    [#-- Seperates resources from their component templates in to their own deployment --]
    [#list ((deploymentGroupDetails.ResourceSets)!{})?values?filter(s -> s.Enabled ) as resourceSet ]
        [#if getCLODeploymentUnit() == resourceSet["deployment:Unit"] ]

            [#assign groupDeploymentUnits = resourceSet["GroupDeploymentUnit"]]
            [#assign ignoreDeploymentUnitSubsetInOutputs = resourceSet["GroupDeploymentUnit"]]

            [#local contractSubsets = []]
            [#list resourceSet.ResourceLabels as label ]
                [#local resourceLabel = getResourceLabel(label, getDeploymentLevel()) ]
                [#local contractSubsets = combineEntities( contractSubsets, (resourceLabel.Subsets)![], UNIQUE_COMBINE_BEHAVIOUR ) ]
            [/#list]

            [#if getCLODeploymentUnitSubset() == "generationcontract"]
                [#assign groupDeploymentUnits = false]
                [#assign ignoreDeploymentUnitSubsetInOutputs = false]

                [#-- We need to initialise the outputs here since we are adding to it out side of the component flow --]
                [@addDefaultGenerationContract subsets=contractSubsets templateSubset=getCLODeploymentUnit() /]
            [/#if]
        [/#if]
    [/#list]

    [@generateOutput
        deploymentFramework=getCLODeploymentFramework()
        type=getCLODeploymentOutputType()
        format=getCLODeploymentOutputFormat()
        level=getDeploymentLevel()
        include=(.vars[deploymentGroupDetails.CompositeTemplate])!""
    /]
[/#macro]

[#-- Add seeder for command line options --]
[#macro shared_entrance_deployment_inputsteps ]

    [@registerInputSeeder
        id=DEPLOYMENT_ENTRANCE_TYPE
        description="Entrance"
    /]

    [@addSeederToConfigPipeline
        stage=COMMANDLINEOPTIONS_SHARED_INPUT_STAGE
        seeder=DEPLOYMENT_ENTRANCE_TYPE
    /]

[/#macro]

[#-- Adjust the subset if required --]
[#function deployment_configseeder_commandlineoptions filter state]
    [#local deploymentGroupDetails = getDeploymentGroupDetails(state.CommandLineOptions.Deployment.Group.Name)]

    [#-- ResourceSets  --]
    [#-- Separates resources from their component templates in to their own deployment --]
    [#list ((deploymentGroupDetails.ResourceSets)!{})?values?filter(s -> s.Enabled ) as resourceSet ]
        [#if state.CommandLineOptions.Deployment.Unit.Name == resourceSet["deployment:Unit"] ]

            [#if !((state.CommandLineOptions.Deployment.Unit.Subset)?has_content)]
                [#return
                    addToConfigPipelineClass(
                        state,
                        COMMAND_LINE_OPTIONS_CONFIG_INPUT_CLASS,
                        {
                            "Deployment" : {
                                "Unit" : {
                                    "Subset" : state.CommandLineOptions.Deployment.Unit.Name
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
