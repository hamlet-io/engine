[#ftl]
[#include "setContext.ftl" ]

[#-- Ignore filtering based on deployment unit --]
[#assign allDeploymentUnits = true]

[#-- Generate resources across multiple levels --]
[#assign compositeLists=[segmentList, solutionList, applicationList] ]

[#-- Special processing --]
[#switch deploymentUnit]
    [#case "dashboard"]
        [#-- Collect all the dashboard components across levels --]
        [#assign dashboardComponents = [] ]
        [#assign deploymentUnitSubset = deploymentUnit]
        [#assign ignoreDeploymentUnitSubsetInOutputs = true]
        
        [#-- No effect except addition to the dashboardComponents array --]
        [#assign segmentListMode="dashboard"]
        [#assign solutionListMode="dashboard"]
        [#assign applicationListMode="dashboard"]
        [@includeCompositeLists
            level="multiple"
            compositeLists=compositeLists /]
        
        [#-- Reset to create the dashboard resource --]
        [#assign compositeLists=[segmentList] ]
        [#assign deploymentUnitSubset = ""]
        [#assign allDeploymentUnits = false]
        [#break]

    [#case "iam"]
    [#case "lg"]
        [#assign deploymentUnitSubset = deploymentUnit]
        [#assign ignoreDeploymentUnitSubsetInOutputs = true]
        [#break]
[/#switch]

[@cfTemplate
    level="multiple"
    compositeLists=compositeLists /]
