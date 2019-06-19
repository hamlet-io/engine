[#ftl]
[#include "/setContext.ftl" ]

[#assign categoryId = "account"]

[#-- Special processing --]
[#switch deploymentUnit]
    [#case "iam"]
    [#case "lg"]
        [#if !(deploymentUnitSubset?has_content)]
            [#assign allDeploymentUnits = true]
            [#assign deploymentUnitSubset = deploymentUnit]
            [#assign ignoreDeploymentUnitSubsetInOutputs = true]
        [/#if]
        [#break]
[/#switch]

[@cfTemplate include=accountList /]
