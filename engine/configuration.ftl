[#ftl]

[#assign configurationScopes = {}]

[#macro addConfigurationScope id description ]
    [@internalMergeConfigurationScopes
        id=id
        configuration={
            "Descriptions" : description,
            "ConfigurationSets" : []
        }
    /]
[/#macro]

[#macro addConfigurationSet scopeId id attributes=[] properties=[] configuration={} plugin="" ]
    [#if ! configurationScopes[scopeId]?? ]
        [@fatal
            message="Unsupported Configuration Scope"
            detail="The requested configuration scope could not be found"
            context={
                "Scope" : scopeId,
                "Id" : id,
                "plugin" : plugin
            }
        /]
        [#return]
    [/#if]

    [#local scope = configurationScopes[scopeId] ]

    [#local configurationSet = {
        "Plugin" : plugin,
        "Id" : id,
        "Properties" : asArray(properties),
        "Attributes" : asArray(attributes),
        "Configuration" : configuration
    }]

    [@internalMergeConfigurationScopes
        id=scopeId
        configuration=scope + {
            "ConfigurationSets" :
                    combineEntities(
                        (scope["ConfigurationSets"])![],
                        [ configurationSet ],
                        APPEND_COMBINE_BEHAVIOUR
                    )
        }
    /]
[/#macro]

[#function getConfigurationScope scopeId ]
    [#return (configurationScopes[scopeId])!{} ]
[/#function]

[#function getConfigurationScopes ]
    [#return configurationScopes]
[/#function]

[#function getConfigurationSet scopeId setId]
    [#local configurationScope = getConfigurationScope(scopeId)]
    [#return configurationScope?has_content?then(
        (configurationScope["ConfigurationSets"]?filter(x -> x.Id == setId )[0])!{},
        {}
    ) ]
[/#function]

[#function getConfigurationSets scopeId ]
    [#local configurationScope = getConfigurationScope(scopeId)]
    [#return configurationScope?has_content?then(
        (configurationScope["ConfigurationSets"])![],
        []
    )]
[/#function]

[#function getConfigurationSetIds scopeId ]
    [#local configurationScope = getConfigurationScope(scopeId)]
    [#return configurationScope?has_content?then(
        configurationScope["ConfigurationSets"]?map(x -> x.Id),
        []
    )]
[/#function]

[#-- Internal Configuration Setup --]
[#macro internalMergeConfigurationScopes id configuration]
    [#assign configurationScopes =
        mergeObjects(
            configurationScopes,
            {
                id : configuration
            }
        )]
[/#macro]
