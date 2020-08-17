[#ftl]
[#include "/bootstrap.ftl" ]

[#assign deploymentGroup = getDeploymentGroup(commandLineOptions.Deployment.Group)]
[#assign level = deploymentGroup.Deployment.Level ]
[#assign compositeTemplateContent = (.vars[deploymentGroup.CompositeTemplate])!"" ]

[#-- ResourceSets  --]
[#-- Seperates resources from their component templates in to their own deployment --]
[#list ((deploymentGroup.Deployment.ResourceSets)!{})?values?filter(s -> s.Enabled ) as resourceSet ]
    [#if getDeploymentUnit() == resourceSet.DeploymentUnit ]

        [#assign allDeploymentUnits = true]
        [#assign ignoreDeploymentUnitSubsetInOutputs = true]

        [#assign contractSubsets = []]
        [#list resourceSet.ResourceLabels as label ]
            [#assign resourceLabel = getResourceLabel(label, level) ]
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

[@generateOutput
    deploymentFramework=commandLineOptions.Deployment.Framework.Name
    type=commandLineOptions.Deployment.Output.Type
    format=commandLineOptions.Deployment.Output.Format
    level=level
    include=compositeTemplateContent
/]
