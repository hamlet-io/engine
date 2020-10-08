[#ftl]

[#-- The views flow provides dynamically loaded output processing without the component and occurrence context established before processing]

[#-- Main component processing loop --]
[#macro default_flow_views level ]

    [@includeProviderViewDefinitionConfiguration
        provider=SHARED_PROVIDER
        view=commandLineOptions.View.Name
    /]

    [@includeProviderViewConfiguration
        provider=SHARED_PROVIDER
        view=commandLineOptions.View.Name
    /]

    [@includeProviderViewDefinitionConfiguration
        provider=(commandLineOptions.Deployment.Provider.Names)[0]
        view=commandLineOptions.View.Name
    /]

    [@includeProviderViewConfiguration
        provider=(commandLineOptions.Deployment.Provider.Names)[0]
        view=commandLineOptions.View.Name
    /]

    [#if invokeViewMacro(
            (commandLineOptions.Deployment.Provider.Names)![0],
            commandLineOptions.Entrance.Type,
            commandLineOptions.Deployment.Framework.Name,
            [
                commandLineOptions.Deployment.Unit.Subset
            ])]

            [@debug
                message="View Processing key:" + commandLineOptions.View.Name + "..."
                enabled=false
            /]
    [/#if]
[/#macro]
