[#ftl]
[#include "setContext.ftl"]

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
        [#if !(deploymentUnitSubset?has_content)]
            [#assign allDeploymentUnits = true]
            [#assign deploymentUnitSubset = deploymentUnit]
            [#assign ignoreDeploymentUnitSubsetInOutputs = true]
        [/#if]
        [#break]

[/#switch]

[@cfTemplate level="application" /]
