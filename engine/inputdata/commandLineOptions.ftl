[#ftl]
[#-- Command line options control how the engine behaves --]

[#assign commandLineOptions = {} ]

[#macro addCommandLineOption option={} ]
    [#if option?has_content ]
        [@internalMergeCommandLineOption
            option=option
        /]
    [/#if]
[/#macro]

[#-- Command line options used across a lot of different places --]
[#--macro setDeploymentUnit deploymentUnit ]
    [@addCommandLineOption
        option={
            "Deployment" : {
                "Unit" : {
                    "Name" : deploymentUnit
                }
            }
        }
    /]
[/#macro--]

[#function getRunId ]
    [#return (getCommandLineOptions().Run.Id)!"" ]
[/#function]

[#function getRequestReference ]
    [#return (getCommandLineOptions().References.Request)!"" ]
[/#function]

[#function getConfigurationReference ]
    [#return (getCommandLineOptions().References.Configuration)!"" ]
[/#function]

[#function getCLOInputSource ]
    [#return (getCommandLineOptions().Input.Source)!"" ]
[/#function]

[#function getCLOInputFilter ]
    [#return (getCommandLineOptions().Input.Filter)!"" ]
[/#function]

[#function getEntranceType ]
    [#return (getCommandLineOptions().Entrance.Type)!"" ]
[/#function]

[#function getDeploymentProviders]
    [#return (getCommandLineOptions().Deployment.Provider.Names)![] ]
[/#function]

[#function getFlows]
    [#return (getCommandLineOptions().Flow.Names)![] ]
[/#function]

[#function getView]
    [#return (getCommandLineOptions().View.Name)!"" ]
[/#function]

[#function getDeploymentFramework ]
    [#return (getCommandLineOptions().Deployment.Framework.Name)!"" ]
[/#function]

[#function getDeploymentOutputType ]
    [#return (getCommandLineOptions().Deployment.Output.Type)!"" ]
[/#function]

[#function getDeploymentOutputFormat ]
    [#return (getCommandLineOptions().Deployment.Output.Format)!"" ]
[/#function]

[#function getDeploymentOutputPrefix ]
    [#return (getCommandLineOptions().Deployment.Output.Prefix)!"" ]
[/#function]

[#function getDeploymentUnit ]
    [#return (getCommandLineOptions().Deployment.Unit.Name)!"" ]
[/#function]

[#function getDeploymentUnitSubset ]
    [#return (getCommandLineOptions().Deployment.Unit.Subset)!"" ]
[/#function]

[#function getDeploymentUnitAlternative ]
    [#return (getCommandLineOptions().Deployment.Unit.Alternative)!"" ]
[/#function]

[#function getDeploymentResourceGroup ]
    [#return (getCommandLineOptions().Deployment.ResourceGroup.Name)!"" ]
[/#function]

[#function getCLODeploymentGroup ]
    [#return (getCommandLineOptions().Deployment.Group.Name)!"" ]
[/#function]

[#function getCLODeploymentMode ]
    [#return (getCommandLineOptions().Deployment.Mode)!"" ]
[/#function]

[#function getSegmentRegion]
    [#return (getCommandLineOptions().Regions.Segment)!"" ]
[/#function]

[#function getAccountRegion]
    [#return (getCommandLineOptions().Regions.Account)!"" ]
[/#function]

[#function getCompositeBlueprint]
    [#return (getCommandLineOptions().Composites.Blueprint)!{} ]
[/#function]

[#function getCompositeSettings]
    [#return (getCommandLineOptions().Composites.Settings)!{} ]
[/#function]

[#function getCompositeDefinitions]
    [#return (getCommandLineOptions().Composites.Definitions)!{} ]
[/#function]

[#function getCompositeStackOutputs]
    [#return (getCommandLineOptions().Composites.StackOutputs)![] ]
[/#function]


[#-----------------------------------------------------
-- Internal support functions for blueprint processing --
-------------------------------------------------------]

[#macro internalMergeCommandLineOption option ]
    [#assign commandLineOptions = mergeObjects(
                                    commandLineOptions,
                                    option
    )]
[/#macro]
