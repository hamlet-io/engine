[#ftl]
[#level = "multiple"]
[#include "setContext.ftl" ]

[#-- Ignore filtering based on deployment unit --]
[#assign allDeploymentUnits = true]

[#-- Generate resources across multiple levels --]
[#assign compositeLists=[segmentList, solutionsList, applicationList]

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
        [#include "componentList.ftl"]
        
        [#-- Reset to create the dashboard resource --]
        [#assign compositeLists=[segmentList]
        [#assign deploymentUnitSubset = ""]
        [#assign allDeploymentUnits = false]
        [#break]

    [#case "iam"]
    [#case "lg"]
        [#assign deploymentUnitSubset = deploymentUnit]
        [#assign ignoreDeploymentUnitSubsetInOutputs = true]
        [#break]
[/#switch]

{
    "AWSTemplateFormatVersion" : "2010-09-09",
    [#include "templateMetadata.ftl"],
    "Resources" : {
        [#assign segmentListMode="definition"]
        [#assign solutionListMode="definition"]
        [#assign applicationListMode="definition"]
        [#include "componentList.ftl"]
    },
    
    "Outputs" : {
        [#assign segmentListMode="outputs"]
        [#assign solutionListMode="outputs"]
        [#assign applicationListMode="outputs"]
        [#include "componentList.ftl"]
        [@cfTemplateGlobalOutputs /]
    }
}


