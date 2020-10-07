[#ftl]

[#macro shared_entrance_deploymenttest ]
    [#assign deploymentGroupDetails = getDeploymentGroupDetails(getDeploymentGroup())]
    [#assign compositeTemplateContent = (.vars[deploymentGroupDetails.CompositeTemplate])!"" ]

    [@generateOutput
        deploymentFramework=commandLineOptions.Deployment.Framework.Name
        type=commandLineOptions.Deployment.Output.Type
        format=commandLineOptions.Deployment.Output.Format
        level=getDeploymentLevel()
        include=compositeTemplateContent
    /]
[/#macro]
