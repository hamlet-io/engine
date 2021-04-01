[#ftl]

[#---------------------------------------------
-- Public functions for reference data processing --
-----------------------------------------------]

[#-- Reference Data is extended dynamically by each reference Data type --]
[#assign layerConfiguration = {} ]
[#assign layerData = {}]
[#assign layerActiveData = {}]

[#macro clearLayerData  ]
    [#assign layerData = {}]
    [#assign layerActiveData = {}]
[/#macro]

[#-- Macros to assemble the component configuration --]
[#macro addLayer type referenceLookupType properties attributes inputFilterAttributes ]
    [#local configuration = {
        "Type" : type,
        "ReferenceLookupType" : referenceLookupType,
        "Properties" : asArray(properties),
        "Attributes" : asArray( [ "InhibitEnabled" ] + attributes),
        "InputFilterAttributes" : asArray(inputFilterAttributes)}
    ]

    [@internalMergeLayerConfiguration
        type=type
        configuration=configuration
    /]

    [#-- Register input filter attributes for layer --]
    [#list asArray(inputFilterAttributes) as inputFilterAttribute]
        [@registerLayerInputFilterAttribute
            id=inputFilterAttribute.Id
            description=inputFilterAttribute.Description
        /]
    [/#list]
[/#macro]

[#macro addLayerData type data={} ]
    [#local layerConfig = layerConfiguration[type] ]
    [#if layerConfig?has_content]
        [@internalMergeLayerData
            type=layerConfig.Type
            data=data
        /]
    [/#if]
[/#macro]

[#macro setActiveLayer type commandLineOptionId data={} ]
    [#local layerConfig = getLayerConfiguration(type) ]
    [#local layerData = {}]

    [#local layerId = commandLineOptionId ]
    [#if data.Id?? && data.Id?has_content ]
        [#local layerId = data.Id ]
    [/#if]

    [#if layerConfig?has_content ]
        [#if layerConfig.ReferenceLookupType?has_content ]
            [#local layerData = getLayer(type, layerId )]
        [/#if]

        [#local layerDetails = mergeObjects(layerData, data + { "Id" : layerId } )  ]

        [@internalMergeLayerActiveData
            type=type
            data=layerDetails
        /]

        [@internalMergeLayerData
            type=type
            data={
                layerId : layerDetails
            }
        /]
    [/#if]
[/#macro]

[#function getLayerConfiguration type ]
    [#local layerConfig = layerConfiguration[type]]
    [#if layerConfig?has_content ]
        [#return layerConfig ]
    [#else]
        [@fatal
            message="Could not find layer configuration"
            detail=type
        /]
        [#return {}]
    [/#if]
[/#function]

[#function getLayer type id="" ]
    [#local layerConfig = layerConfiguration[type]]
    [#if layerConfig?has_content && (layerConfig.ReferenceLookupType)?has_content ]
        [#if id?has_content ]
            [#return (layerData[layerConfig.ReferenceLookupType][id])!{} ]
        [#else]
            [#return (layerData[layerConfig.ReferenceLookupType])!{}]
        [/#if]
    [/#if]
    [#return {}]
[/#function]

[#function getActiveLayer type ]
    [#local layer = (layerActiveData[type])!{} ]
    [#if layer?has_content]
        [#return layer ]
    [#else]
        [@fatal
            message="Could not find layer"
            detail=type
        /]
        [#return {} ]
    [/#if]
[/#function]

[#function getActiveLayers ]
    [#return layerActiveData]
[/#function]

[#-- Searches all layers for a given attribute - attribute provided as array of keys --]
[#-- Returns all of the attribute values found on the layers --]
[#function getActiveLayerAttributes attributePath layers=[ "*" ] default=[] ]
    [#local results = [] ]
    [#-- Process layers in turn assuming the order provided is the preferred order --]
    [#list layers as layer]
        [#-- Look up the active data --]
        [#list getActiveLayers() as type, layerData ]
            [#if (layer == type) || (layer == "*") ]
                [#local layerAttribute = findAttributeInObject( layerData, attributePath ) ]
                [#if layerAttribute?has_content ]
                    [#local results += [ layerAttribute ] ]
                [/#if]
            [/#if]
        [/#list]
    [/#list]

    [#return results + asArray(default) ]
[/#function]

[#macro includeLayers cloLayers blueprint]
    [#list layerConfiguration as id, layer ]
        [@addLayerData
            type=layer.Type
            data=(blueprint[layer.ReferenceLookupType])!{}
        /]
        [@setActiveLayer
            type=layer.Type
            commandLineOptionId=(cloLayers[layer.Type])!""
            data=blueprint[layer.Type]
        /]
    [/#list]
[/#macro]

[#-------------------------------------------------------
-- Internal support functions for component processing --
---------------------------------------------------------]

[#-- Helper macro - not for general use --]
[#macro internalMergeLayerConfiguration type configuration]
    [#assign layerConfiguration =
        mergeObjects(
            layerConfiguration,
            {
                type : configuration
            }
        )]
[/#macro]

[#macro internalMergeLayerData type data=[] ]
    [#local layerConfig = (layerConfiguration[type])!{} ]
    [#if layerConfig?has_content ]
        [#if data?has_content ]
            [#list data as id,content ]
                [#local compositeData = getCompositeObject(layerConfig.Attributes, addIdNameToObject( content, content.Id )) ]
                [#assign layerData =
                    mergeObjects(
                        layerData,
                        {
                            layerConfig.ReferenceLookupType : {
                                id : compositeData
                            }
                        }
                    )]
            [/#list]
        [/#if]
    [#else]
        [@fatal
            message="Attempt to add data for unknown layer reference data type"
            detail=type
        /]
    [/#if]
[/#macro]

[#macro internalMergeLayerActiveData type data={} ]
    [#local layerConfig = (layerConfiguration[type])!{} ]
    [#if layerConfig?has_content ]
        [#assign layerActiveData =
            mergeObjects(
                layerActiveData,
                {
                    type : getCompositeObject( layerConfig.Attributes, addIdNameToObject( data, data.Id ))
                }
            )]
    [/#if]
[/#macro]
