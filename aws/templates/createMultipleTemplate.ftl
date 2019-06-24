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

[@cf_template level="segment" /]
[@cf_template level="solution" /]
[@cf_template level="application" /]
