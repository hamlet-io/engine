[#ftl]
[#include "/bootstrap.ftl" ]

[#-- Ignore filtering based on deployment unit --]
[#assign allDeploymentUnits = true]

[#-- Special processing --]
[#switch deploymentUnit]
    [#case "iam"]
    [#case "lg"]
        [#assign deploymentUnitSubset = deploymentUnit]
        [#assign ignoreDeploymentUnitSubsetInOutputs = true]
        [#break]
[/#switch]

[@cfTemplate level="segment" /]
[@cfTemplate level="solution" /]
[@cfTemplate level="application" /]
