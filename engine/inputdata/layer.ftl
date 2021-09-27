[#ftl]

[#-----------------------------------------
-- Public functions for layer processing --
-------------------------------------------]

[#-- Layer Data is extended dynamically by each layer type --]
[#assign layerConfiguration = {} ]

[#-- Macro to assemble the layer configuration --]
[#-- The reference type is an object where each child attribute  --]
[#-- contains common or reference attribute values for the layer --]
[#macro addLayer type referenceLookupType properties attributes inputFilterAttributes=[] ]
    [#local configuration =
        {
            "Type" : type,
            "ReferenceLookupType" : referenceLookupType,
            "Properties" : asArray(properties),
            "Attributes" : asArray( [ "InhibitEnabled" ] + attributes),
            "InputFilterAttributes" : asArray(inputFilterAttributes)
        }
    ]

    [#assign layerConfiguration =
        mergeObjects(
            layerConfiguration,
            {
                type : configuration
            }
        )
    ]

    [#-- Register input filter attributes for layer        --]
    [#-- For now only one attribute per layer is supported --]
    [#-- pending identification of a use case              --]
    [#if configuration.InputFilterAttributes?size != 1]
        [@fatal
            message="A layer must be configured with one input filter attribute"
            detail=configuration
        /]
    [#else]
        [#local inputFilterAttribute = configuration.InputFilterAttributes[0] ]
        [#if inputFilterAttribute.Id??]
            [@registerLayerInputFilterAttribute
                id=inputFilterAttribute.Id
                description=inputFilterAttribute.Description
            /]
        [#else]
            [@fatal
                message="Layer input filter attribute must have an Id"
                context=configuration
            /]
        [/#if]
     [/#if]
[/#macro]

[#-- Check if layer is configured/known --]
[#function isLayerConfigured type ]
    [#return layerConfiguration[type]?? ]
[/#function]

[#-- Fetch configuration of a layer             --]
[#-- Assumes layer is expected to be configured --]
[#function getLayerConfiguration type ]
    [#local layerConfig = layerConfiguration[type]]
    [#if layerConfig?has_content ]
        [#return layerConfig ]
    [#else]
        [@fatal
            message="Could not find layer configuration"
            detail=type
        /]
        [#return {} ]
    [/#if]
[/#function]

[#-- Return the layer input filter attributes --]
[#function getLayerInputFilterAttributes type ]
    [#local attributeValue = (getLayerConfiguration(type).InputFilterAttributes[0].Id)!"" ]
    [#return arrayIfContent(attributeValue, attributeValue) ]
[/#function]

[#-- Check if layer is active based on its presence in the current input state --]
[#function isLayerActive type]
    [#return getActiveLayers()[type]?? ]
[/#function]

[#-- Fetch the current configuration for a layer --]
[#-- Assumes layer is expected to be active --]
[#function getActiveLayer type ]
    [#local activeData = getActiveLayers() ]
    [#-- Layer may not be active depending on the input filter --]
    [#if activeData[type]?? ]
        [#return activeData[type] ]
    [#else]
        [@fatal
            message="Could not find layer"
            detail=type
        /]
        [#return {} ]
    [/#if]
[/#function]

[#-- Searches all layers for a given attribute - attribute provided as array of keys --]
[#-- Returns all of the attribute values found on the layers --]
[#function getActiveLayerAttributes attributePath layers=[ "*" ] default=[] layersState={} ]

    [#return
        internalGetActiveLayerAttributes(
            attributePath,
            layersState?has_content?then(
                layersState,
                getActiveLayers()
            ),
            layers,
            default
        )
    ]
[/#function]

[#-----------------------------------------------------
-- Friend functions for use by input processing only --
-------------------------------------------------------]

[#-- Determine the layer input state --]
[#function friendGetActiveLayersState filter blueprint]
    [#local result = {} ]

    [#list layerConfiguration as id, configuration ]
        [#if internalIsActiveLayer(configuration, filter) ]
            [#local result +=
                {
                    configuration.Type :
                        internalGetLayerState(
                            configuration,
                            filter,
                            blueprint,
                            configuration.Attributes
                        )
                }
            ]
        [/#if]
    [/#list]

    [#return result]
[/#function]

[#-- Determine the layer filter attribute values --]
[#function friendGetActiveLayersFilter filter blueprint]
    [#local result = {} ]

    [#list layerConfiguration as id, configuration ]
        [#if internalIsActiveLayer(configuration, filter) ]
            [#local result +=
                internalGetFilterAttributeForLayer(
                    configuration,
                    internalGetLayerState(
                        configuration,
                        filter,
                        blueprint,
                        [
                            "InhibitEnabled",
                            {
                                "Names" : "Id",
                                "Types" : STRING_TYPE
                            },
                            {
                                "Names" : "Name",
                                "Types" : STRING_TYPE
                            }
                        ]
                    )
                )
            ]
        [/#if]
    [/#list]
    [#return result]
[/#function]

[#-- Determine the layers filter attribute values from --]
[#-- previously calculated layers state                --]
[#function friendGetActiveLayersFilterFromLayerState layersState]
    [#local result = {} ]

    [#list layersState as type, layerState ]
        [#local result +=
            internalGetFilterAttributeForLayer(
                getLayerConfiguration(type),
                layerState
            )
        ]
    [/#list]

    [#return result]
[/#function]

[#---------------------------------------------------
-- Internal support functions for layer processing --
-----------------------------------------------------]

[#-- Determine if the layer is active based on the provided input filter --]
[#function internalIsActiveLayer configuration filter ]
    [#-- Temporarily assume that if a layer is known, it is active --]
    [#-- This is mainly to handle the solution layer. Future       --]
    [#-- refactoring will see it removed as a layer and handled by --]
    [#-- more general solution handling code                       --]
    [#-- TODO(mfl): Remove once solution is no longer a layer      --]
    [#return true]

    [#if getFilterAttribute(filter, configuration.InputFilterAttributes[0].Id)?has_content]
        [#-- Assume only one attribute per filter --]
        [#return true]
    [/#if]

    [#-- No matching attribute found --]
    [#return false]
[/#function]

[#-- Create a filter attribute corresponding to a layer --]
[#function internalGetFilterAttributeForLayer configuration data ]
    [#-- Assume only one attribute per filter --]
    [#local values =
        getUniqueArrayElements(
            arrayIfTrue(data.Id!"", data.Id??),
            arrayIfTrue(data.Name!"", data.Name??)
        )
    ]
    [#return
        attributeIfContent(
            configuration.InputFilterAttributes[0].Id,
            values
        )
    ]
[/#function]

[#-- Determine the layer state based on any layer data, --]
[#-- reference data or input filter attribute values    --]
[#function internalGetLayerState configuration filter blueprint attributes ]

    [#-- Start with what we can glean from various sources --]
    [#local filterState = internalGetLayerFilterData(configuration, filter) ]
    [#local layerState = internalGetLayerData(configuration, blueprint) ]
    [#local layerId = mergeObjects(filterState, layerState).Id!"" ]
    [#local referenceState =
        internalGetLayerReferenceData(
            configuration,
            blueprint,
            layerId
        )
    ]

    [#-- Ensure any reference state is consistent with the layerId --]
    [#if layerId?has_content && referenceState.Id?? && (layerId != referenceState.Id) ]
        [@fatal
            message="Layer reference configuration is inconsistent with layer Id"
            context=referenceState
            detail=layerId
        /]
        [#return {} ]
    [/#if]

    [#-- Now merge in the priority order --]
    [#local state = mergeObjects(filterState, referenceState, layerState) ]

    [#-- Return the requested attributes of the layer --]
    [#return getCompositeObject( attributes, addIdNameToObject( state, state.Id!"" )) ]
[/#function]

[#-- Get layer data from the input filter --]
[#function internalGetLayerFilterData configuration filter ]
    [#-- If more than one value, then filter already has id and name --]
    [#local filterAttributeValues = getFilterAttribute(filter, configuration.InputFilterAttributes[0].Id) ]
    [#if filterAttributeValues?size == 1]
        [#return
            {
                "Id" : filterAttributeValues[0]
            }
        ]
    [/#if]
    [#return {} ]
[/#function]

[#-- Get layer data from the reference data --]
[#function internalGetLayerReferenceData configuration blueprint id ]
    [#return (blueprint[configuration.ReferenceLookupType][id])!{} ]
[/#function]

[#-- Get layer data from the type based layer object --]
[#function internalGetLayerData configuration blueprint ]
    [#return (blueprint[configuration.Type])!{} ]
[/#function]

[#-- Searches provided layer data for a given attribute - attribute provided as array of keys --]
[#-- Returns all of the attribute values found on the layers --]
[#function internalGetActiveLayerAttributes attributePath layersState layers default ]
    [#local results = [] ]
    [#-- Process layers in turn assuming the order provided is the preferred order --]
    [#list layers as layer]
        [#-- Look up the active data --]
        [#list layersState as type, layerData ]
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

