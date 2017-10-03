[#ftl]
[#include "setContext.ftl"]

[#-- Special processing --]
[#switch deploymentUnit]
    [#case "eip"]
    [#case "iam"]
    [#case "lg"]
        [#assign allDeploymentUnits = true]
        [#assign deploymentUnitSubset = deploymentUnit]
        [#assign ignoreDeploymentUnitSubsetInOutputs = true]
        [#break]
[/#switch]

[@cfTemplate
    level="solution"
    compositeLists=solutionList /]
