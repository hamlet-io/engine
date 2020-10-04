[#ftl]

[#assign deploymentGroupDetails = getDeploymentGroupDetails(getDeploymentGroup())]
[#assign compositeTemplateContent = (.vars[deploymentGroupDetails.CompositeTemplate])!"" ]

[#-- ResourceSets  --]
[#-- Seperates resources from their component templates in to their own deployment --]
[#list ((deploymentGroupDetails.ResourceSets)!{})?values?filter(s -> s.Enabled ) as resourceSet ]
    [#if getDeploymentUnit() == resourceSet["deployment:Unit"] ]

        [#assign allDeploymentUnits = true]
        [#assign ignoreDeploymentUnitSubsetInOutputs = true]

        [#assign contractSubsets = []]
        [#list resourceSet.ResourceLabels as label ]
            [#assign resourceLabel = getResourceLabel(label, getDeploymentLevel()) ]
            [#assign contractSubsets = combineEntities( contractSubsets, (resourceLabel.Subsets)![], UNIQUE_COMBINE_BEHAVIOUR ) ]
        [/#list]

        [#if (commandLineOptions.Deployment.Unit.Subset!"") == "generationcontract"]
            [#assign allDeploymentUnits = false]
            [#assign ignoreDeploymentUnitSubsetInOutputs = false]

            [@initialiseDefaultScriptOutput format=commandLineOptions.Deployment.Output.Format /]
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


[#if (commandLineOptions.Deployment.Unit.Subset!"") == "generationcontract" ]
    [@addDefaultGenerationContract subsets="testcase" /]
[/#if]

[@generateOutput
    deploymentFramework=commandLineOptions.Deployment.Framework.Name
    type=commandLineOptions.Deployment.Output.Type
    format=commandLineOptions.Deployment.Output.Format
    level=getDeploymentLevel()
    include=compositeTemplateContent
/]
