[#ftl]
[#------------------------------------------
-- Public functions for passthrough processing --
--------------------------------------------]

[#-- Legacy processing doesn't have a model --]
[#function default_model_passthrough args=[] ]
    [#return {} ]
[/#function]

[#-- Main component processing loop --]
[#macro default_model_passthrough_scope_view level ]

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
            commandLineOptions.DocumentSet.Type,
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
