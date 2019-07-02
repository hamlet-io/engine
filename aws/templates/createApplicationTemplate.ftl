[#ftl]
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
            [@addToDefaultScriptOutput getGenerationPlan("template") /]
        [#else]
            [#if !(deploymentUnitSubset?has_content)]
                [#assign allDeploymentUnits = true]
                [#assign deploymentUnitSubset = deploymentUnit]
                [#assign ignoreDeploymentUnitSubsetInOutputs = true]
            [/#if]
        [/#if]
        [#break]

[/#switch]

[@generateOutput
    deploymentFramework=deploymentFramework
    type=outputType
    format=outputFormat
    level="segment"
/]
