[#ftl]
[#include "setContext.ftl" ]

[#-- Ignore filtering based on deployment unit --]
[#assign allDeploymentUnits = true]

[#-- Generate resources across multiple levels --]
[#assign levels=["segment", "solution", "application"] ]

[#-- Special processing --]
[#switch deploymentUnit]
    [#case "dashboard"]
        [#-- Collect all the dashboard components across levels --]
        [#assign dashboardComponents = [] ]
        [#assign deploymentUnitSubset = deploymentUnit]
        [#assign ignoreDeploymentUnitSubsetInOutputs = true]

        [#-- No effect except addition to the dashboardComponents array --]
        [#assign listMode="dashboard"]
        [@includeLevelTemplates levels /]
        [@processComponents levels /]

        [#-- Reset to create the dashboard resource --]
        [#assign levels=["segment"] ]
        [#assign deploymentUnitSubset = ""]
        [#assign allDeploymentUnits = false]
        [#break]

    [#case "iam"]
    [#case "lg"]
        [#assign deploymentUnitSubset = deploymentUnit]
        [#assign ignoreDeploymentUnitSubsetInOutputs = true]
        [#break]
[/#switch]

[#assign componentLevel="multiple" ]
[@cfTemplate levels=levels /]

