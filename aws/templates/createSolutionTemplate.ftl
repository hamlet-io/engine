[#ftl]
[#include "/bootstrap.ftl" ]

[#-- Special processing --]
[#switch deploymentUnit]
    [#case "eip"]
    [#case "iam"]
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
    level="solution"
/]
