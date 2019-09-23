[#ftl]
[#include "/bootstrap.ftl" ]

[#-- Special processing --]
[#switch commandLineOptions.Deployment.Unit.Name]
    [#case "eip"]
    [#case "iam"]
    [#case "lg"]
    [#case "s3"]
    [#case "cmk"]
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
                                    "Subset" : commandLineOptions.Deployment.Unit.Name
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
    level="segment"
/]
