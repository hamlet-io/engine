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
            "Type" : type,
            "PluralType" : getReferenceBlueprintKey(type),
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
    [#list getLayerConfiguration() as type,layerConfig ]
        [#local layerConfigDescription = layerConfig.Properties?filter( prop -> prop.Type == "Description")?map( prop -> prop.Value )?join(' ') ]

        [#local layerTypeDetails = {
            "Type" : type,
            "ReferenceLookupType" : (layerConfig.Configuration.ReferenceLookupType)!"",
            "Description" : layerConfigDescription,
            "Attributes" : layerConfig.Attributes
        }]

        [@infoContent
            type="layertypes"
            id=type
            details=layerTypeDetails
        /]

        [#list (getBlueprint()[layerConfig.Configuration.ReferenceLookupType])!{} as layerId,layerData ]

            [#local layerDataDetails = {
                "Type" : type,
                "Id" : layerId,
                "Name" : (layerData.Name)!layerId,
                "Active" : false,
                "Properties" : layerData
            }]

            [@infoContent
                type="layerdata"
                id=layerId
                details=layerDataDetails
            /]
        [/#list]
    [/#list]

    [#list getActiveLayers() as type,layerData ]

        [#local layerDataDetails = {
            "Type" : type,
            "Id" : layerData.Id,
            "Name" : (layerData.Name)!layerData.Id,
            "Active" : true,
            "Properties" : layerData
        }]

        [@infoContent
            type="layerdata"
            id=layerData.Id
            details=layerDataDetails
        /]

    [/#list]

    [#-- Components --]
    [#list getAllComponentConfiguration() as type,componentConfig ]

        [#local componentConfigDescription = asFlattenedArray(
                componentConfig.Properties?filter( prop -> prop.Type == "Description")?map( prop -> prop.Value )
            )?join(' ') ]

        [#local componentAttributes = []]

        [#list getComponentResourceGroups(type) as id, resourceGroup ]

            [#list combineEntities([ SHARED_PROVIDER ], getLoaderProviders(), UNIQUE_COMBINE_BEHAVIOUR) as provider ]

                [#local componentAttributes = combineEntities(
                        componentAttributes,
                        getComponentResourceGroupAttributes(resourceGroup, provider),
                        MERGE_COMBINE_BEHAVIOUR)]
            [/#list]
        [/#list]

        [#local componentTypeDetails = {
            "Type" : type,
            "Description" : componentConfigDescription,
            "Attributes" : componentAttributes
        }]

        [@infoContent
            type="componenttypes"
            id=type
            details=componentTypeDetails
        /]
    [/#list]
[/#macro]
