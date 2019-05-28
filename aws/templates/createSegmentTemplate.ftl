[#ftl]
[#include "setContext.ftl" ]

[#-- Special processing --]
[#switch deploymentUnit]
    [#case "eip"]
    [#case "iam"]
    [#case "lg"]
    [#case "s3"]
    [#case "cmk"]
        [#if !(deploymentUnitSubset?has_content)]
            [#assign allDeploymentUnits = true]
            [#assign deploymentUnitSubset = deploymentUnit]
            [#assign ignoreDeploymentUnitSubsetInOutputs = true]
        [/#if]
        [#break]
[/#switch]

[#assign componentLevel="segment" ]
[@cfTemplate
    level=componentLevel
    compositeLists=segmentList /]


