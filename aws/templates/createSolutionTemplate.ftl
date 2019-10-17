[#ftl]
[#include "/bootstrap.ftl" ]

[#-- Add tests to initialised test outputs --]
[#if commandLineOptions.Input.TestCase?has_content &&
        (commandLineOptions.Deployment.Unit.Subset!"") == "testplan" ]
    [@addTestPlanToDefaultJsonOutput tests=testsList /]
[/#if]

[#-- Special processing --]
[#switch getDeploymentUnit()]
    [#case "eip"]
    [#case "iam"]
    [#case "lg"]
        [#if (commandLineOptions.Deployment.Unit.Subset!"") == "genplan"]
            [@initialiseDefaultScriptOutput format=commandLineOptions.Deployment.Output.Format /]
            [@addDefaultGenerationPlan subsets="template" /]
        [#else]
            [#if !(commandLineOptions.Deployment.Unit.Subset?has_content)]
                [#assign allDeploymentUnits = true]
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
                [#assign ignoreDeploymentUnitSubsetInOutputs = true]
            [/#if]
        [/#if]
        [#break]
[/#switch]

[@generateOutput
    deploymentFramework=commandLineOptions.Deployment.Framework.Name
    type=commandLineOptions.Deployment.Output.Type
    format=commandLineOptions.Deployment.Output.Format
    level="solution"
/]
