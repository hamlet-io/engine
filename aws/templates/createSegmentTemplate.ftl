[#ftl]
[#include "/bootstrap.ftl" ]

[#-- Special processing --]
[#switch deploymentUnit]
    [#case "eip"]
    [#case "iam"]
    [#case "lg"]
    [#case "s3"]
    [#case "cmk"]
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
[/#switch]

[@generateOutput
    deploymentFramework=deploymentFramework
    type=outputType
    format=outputFormat
    level="segment"
/]
