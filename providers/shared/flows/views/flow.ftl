[#ftl]

[#-- The views flow provides dynamically loaded output processing without the component and occurrence context established before processing]

[#-- Main component processing loop --]
[#macro default_flow_views level ]

    [@includeProviderViewDefinitionConfiguration
        provider=SHARED_PROVIDER
        view=getCLOView()
    /]

    [@includeProviderViewConfiguration
        provider=SHARED_PROVIDER
        view=getCLOView()
    /]

    [#local primaryProvider = (getLoaderProviders()[0])!SHARED_PROVIDER ]

    [@includeProviderViewDefinitionConfiguration
        provider=primaryProvider
        view=getCLOView()
    /]

    [@includeProviderViewConfiguration
        provider=primaryProvider
        view=getCLOView()
    /]

    [#if invokeViewMacro(
            primaryProvider,
            getCLODeploymentFramework(),
            getCLOEntranceType(),
            [
                getCLODeploymentUnitSubset()
            ])]

            [@debug
                message="View Processing key:" + getCLOView() + "..."
                enabled=false
            /]
    [/#if]
[/#macro]
