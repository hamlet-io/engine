[#ftl]

[#macro shared_view_default_info_generationcontract  ]
    [@addDefaultGenerationContract subsets=[ "info" ] /]
[/#macro]

[#macro shared_view_default_info ]

    [#-- Load sections which are dynamically loaded through discovery --]
    [#local providersList = asFlattenedArray( [ SHARED_PROVIDER, getLoaderProviders() ] ) ]
    [@includeAllComponentDefinitionConfiguration providersList /]
    [@includeAllViewConfiguration providersList /]

    [#-- Provider details --]
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

        [@infoContent
            type="providers"
            id=id
            details=providerDetails
        /]
    [/#list]

    [#-- Entrances --]
    [#list getEntranceTypes() as type ]
        [#local entranceProperties = getEntranceProperties(type)]
        [#local entranceDescription = entranceProperties?filter( prop -> prop.Type == "Description")?map( prop -> prop.Value )?join(' ') ]

        [#local entranceDetails = {
            "Type" : type,
            "Description" : entranceDescription,
            "CommandLineOptions" : getEntranceCommandLineOptions(type)
        }]
        [@infoContent
            type="entrances"
            id=type
            details=entranceDetails
        /]
    [/#list]

    [#-- References --]
    [#list getReferenceConfiguration() as type,referenceConfig ]
        [#local referenceConfigDescription = referenceConfig.Properties?filter( prop -> prop.Type == "Description")?map( prop -> prop.Value )?join(' ') ]

        [#local referenceTypeDetails = {
            "Type" : referenceConfig.Type.Singular,
            "PluralType" : referenceConfig.Type.Plural,
            "Description" : referenceConfigDescription,
            "Attributes" : referenceConfig.Attributes
        }]

        [@infoContent
            type="referencetypes"
            id=type
            details=referenceTypeDetails
        /]

    [/#list]

    [#list getAllReferenceData() as type, data ]
        [#local referenceDataDetails = []]
        [#list data as id,content ]

            [#local referenceDataDetails = combineEntities(
                referenceDataDetails,
                [
                    {
                        "Type" : type,
                        "Id" : id,
                        "Properties" : content
                    }
                ],
                APPEND_COMBINE_BEHAVIOUR
            )]
        [/#list]

        [@infoContent
            type="referencedata"
            id=type
            details=referenceDataDetails
        /]
    [/#list]

    [#-- Layers --]
    [#list getAllLayerConfiguration() as type,layerConfig ]
        [#local layerConfigDescription = layerConfig.Properties?filter( prop -> prop.Type == "Description")?map( prop -> prop.Value )?join(' ') ]

        [#local layerTypeDetails = {
            "Type" : layerConfig.Type,
            "ReferenceLookupType" : (layerConfig.ReferenceLookupType)!"",
            "Description" : layerConfigDescription,
            "Attributes" : layerConfig.Attributes
        }]

        [@infoContent
            type="layertypes"
            id=type
            details=layerTypeDetails
        /]

        [#list (getBlueprint()[layerConfig.ReferenceLookupType])!{} as layerId,layerData ]

            [#local layerDataDetails = {
                "Type" : type,
                "Id" : layerId,
                "Properties" : layerData
            }]

            [@infoContent
                type="layerdata"
                id=layerId
                details=layerDataDetails
            /]
        [/#list]
    [/#list]

[/#macro]
