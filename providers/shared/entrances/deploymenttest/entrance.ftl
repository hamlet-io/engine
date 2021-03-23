[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_deploymenttest ]

    [#local deploymentGroupDetails = getDeploymentGroupDetails(getDeploymentGroup())]

    [@generateOutput
        deploymentFramework=getCLODeploymentFramework()
        type=getCLODeploymentOutputType()
        format=getCLODeploymentOutputFormat()
        level=getDeploymentLevel()
        include=(.vars[deploymentGroupDetails.CompositeTemplate])!""
    /]
[/#macro]
