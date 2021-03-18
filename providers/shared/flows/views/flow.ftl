[#ftl]

[#-- The views flow provides dynamically loaded output processing without the component and occurrence context established before processing]

[#-- Main component processing loop --]
[#macro default_flow_views level ]

    [@includeProviderViewDefinitionConfiguration
        provider=SHARED_PROVIDER
        view=getView()
    /]

    [@includeProviderViewConfiguration
        provider=SHARED_PROVIDER
        view=getView()
    /]

    [#local primaryProvider = (getDeploymentProviders()[0])!SHARED_PROVIDER ]

    [@includeProviderViewDefinitionConfiguration
        provider=primaryProvider
        view=getView()
    /]

    [@includeProviderViewConfiguration
        provider=primaryProvider
        view=getView()
    /]

    [#if invokeViewMacro(
            primaryProvider,
            getDeploymentFramework(),
            getEntranceType(),
            [
                getDeploymentUnitSubset()
            ])]

            [@debug
                message="View Processing key:" + getView() + "..."
                enabled=false
            /]
    [/#if]
[/#macro]
