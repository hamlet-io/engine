[#ftl]
[#if (deploymentUnit == "model")  &&
    (!((deploymentUnitSubset!"") == "genplan"))]
    [#assign deploymentFrameworkModel = ""]
[/#if]
[#include "/bootstrap.ftl" ]

[#-- Special processing --]
[#switch deploymentUnit]
    [#case "iam"]
        [#if deploymentUnitSubset?has_content &&
            (deploymentUnitSubset == "pregeneration") ]
            [#assign allDeploymentUnits = true]
            [#assign ignoreDeploymentUnitSubsetInOutputs = true]
            [#break]
        [/#if]
        [#-- Fall through to lg processing --]
    [#case "lg"]
        [#if (deploymentUnitSubset!"") == "genplan"]
            [@initialiseDefaultScriptOutput format=outputFormat /]
            [@addDefaultGenerationPlan subsets="template" /]
        [#else]
            [#if !(deploymentUnitSubset?has_content)]
                [#assign allDeploymentUnits = true]
                [#assign deploymentUnitSubset = deploymentUnit]
                [#assign ignoreDeploymentUnitSubsetInOutputs = true]
            [/#if]
        [/#if]
        [#break]
    [#case "model"]
        [#if (deploymentUnitSubset!"") == "genplan"]
            [@initialiseDefaultScriptOutput format=outputFormat /]
            [@addDefaultGenerationPlan subsets="config" /]
        [#else]
            [#assign outputType = "model"]
        [/#if]

[/#switch]

[@generateOutput
    deploymentFramework=deploymentFramework
    type=outputType
    format=outputFormat
    level="application"
/]
