[#ftl]

[#-- Entrance logic --]
[#macro shared_entrance_deploymenttest ]

    [@generateOutput
        deploymentFramework=getDeploymentFramework()
        type=getDeploymentOutputType()
        format=getDeploymentOutputFormat()
        level=getDeploymentLevel()
        include=(.vars[deploymentGroupDetails.CompositeTemplate])!""
    /]
[/#macro]
