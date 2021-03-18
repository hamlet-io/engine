[#ftl]

[#macro shared_view_default_info_generationcontract  ]
    [@addDefaultGenerationContract subsets=[ "info" ] /]
[/#macro]

[#macro shared_view_default_info ]

    [#-- Load sections which are dynamically loaded through discovery --]
    [#local providersList = asFlattenedArray( [ SHARED_PROVIDER, getDeploymentProviders() ] ) ]
    [@includeAllComponentDefinitionConfiguration providersList /]
    [@includeAllViewConfiguration providersList /]

    [#list providerDictionary as id,provider ]
        [#local providerLocation = ""]
        [#list providerMarkers as providerMarker ]
            [#if providerMarker.Path?keep_after_last("/") == id ]
                [#local providerLocation = providerMarker.Path ]
                [#break]
            [/#if]
        [/#list]

        [#local providerDetails =
            {
                "Name" : id,
                "Location" : providerLocation,
                "Components" : getProviderComponentNames(id),
                "Views" : getProviderViewNames(id)
            }
        ]

        [@infoProvider
            id=id
            details=providerDetails
        /]
    [/#list]

    [#list getEntranceTypes() as type ]
        [#local entranceProperties = getEntranceProperties(type)]
        [#local entranceDescription = entranceProperties?filter( prop -> prop.Type == "Description")?map( prop -> prop.Value )?join(' ') ]

        [#local entranceDetails = {
            "Type" : type,
            "Description" : entranceDescription,
            "CommandLineOptions" : getEntranceCommandLineOptions(type)
        }]
        [@infoEntrance
            id=type
            details=entranceDetails
        /]

    [/#list]
[/#macro]
