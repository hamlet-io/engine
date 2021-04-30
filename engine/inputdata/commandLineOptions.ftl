[#ftl]

[#-- Command line option accessors --]

[#function getCLORunId ]
    [#return (getCommandLineOptions().Run.Id)!"" ]
[/#function]

[#function getCLORequestReference ]
    [#return (getCommandLineOptions().References.Request)!"" ]
[/#function]

[#function getCLOConfigurationReference ]
    [#return (getCommandLineOptions().References.Configuration)!"" ]
[/#function]

[#function getCLOInputSource ]
    [#return (getCommandLineOptions().Input.Source)!"" ]
[/#function]

[#function getCLOInputFilter ]
    [#return (getCommandLineOptions().Input.Filter)!"" ]
[/#function]

[#function getCLOEntranceType ]
    [#return (getCommandLineOptions().Entrance.Type)!"" ]
[/#function]

[#function getCLODeploymentProviders]
    [#return (getCommandLineOptions().Deployment.Provider.Names)![] ]
[/#function]

[#function getCLOFlows]
    [#return (getCommandLineOptions().Flow.Names)![] ]
[/#function]

[#function getCLOView]
    [#return (getCommandLineOptions().View.Name)!"" ]
[/#function]

[#function getCLODeploymentFramework ]
    [#return (getCommandLineOptions().Deployment.Framework.Name)!"" ]
[/#function]

[#function getCLODeploymentOutputType ]
    [#return (getCommandLineOptions().Deployment.Output.Type)!"" ]
[/#function]

[#function getCLODeploymentOutputFormat ]
    [#return (getCommandLineOptions().Deployment.Output.Format)!"" ]
[/#function]

[#function getCLODeploymentOutputPrefix ]
    [#return (getCommandLineOptions().Deployment.Output.Prefix)!"" ]
[/#function]

[#function getCLODeploymentUnit ]
    [#return (getCommandLineOptions().Deployment.Unit.Name)!"" ]
[/#function]

[#function getCLODeploymentUnitSubset ]
    [#return (getCommandLineOptions().Deployment.Unit.Subset)!"" ]
[/#function]

[#function getCLODeploymentUnitAlternative ]
    [#return (getCommandLineOptions().Deployment.Unit.Alternative)!"" ]
[/#function]

[#function getCLODeploymentResourceGroup ]
    [#return (getCommandLineOptions().Deployment.ResourceGroup.Name)!"" ]
[/#function]

[#function getCLODeploymentGroup ]
    [#return (getCommandLineOptions().Deployment.Group.Name)!"" ]
[/#function]

[#function getCLODeploymentMode ]
    [#return (getCommandLineOptions().Deployment.Mode)!"" ]
[/#function]

[#function getCLOSegmentRegion]
    [#return (getCommandLineOptions().Regions.Segment)!"" ]
[/#function]

[#function getCLOAccountRegion]
    [#return (getCommandLineOptions().Regions.Account)!"" ]
[/#function]

[#function getCLOCompositeBlueprint]
    [#return (getCommandLineOptions().Composites.Blueprint)!{} ]
[/#function]

[#function getCLOCompositeSettings]
    [#return (getCommandLineOptions().Composites.Settings)!{} ]
[/#function]

[#function getCLOCompositeDefinitions]
    [#return (getCommandLineOptions().Composites.Definitions)!{} ]
[/#function]

[#function getCLOCompositeStackOutputs]
    [#return (getCommandLineOptions().Composites.StackOutputs)![] ]
[/#function]
