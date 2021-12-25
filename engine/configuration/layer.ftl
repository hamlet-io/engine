[#ftl]

[#-- Layers control the context of your deployment and contorl where resources can be created --]
[#assign LAYER_CONFIGURATION_SCOPE = "Layer" ]

[@addConfigurationScope
    id=LAYER_CONFIGURATION_SCOPE
    description="Layers control the context of your deployment"
/]

[#-- Macro to assemble the layer configuration --]
[#-- The reference type is an object where each child attribute  --]
[#-- contains common or reference attribute values for the layer --]
[#macro addLayer type referenceLookupType properties attributes inputFilterAttributes=[] ]

    [#local configuration =
        {
            "Type" : type,
            "ReferenceLookupType" : referenceLookupType,
            "InputFilterAttributes" : asArray(inputFilterAttributes)
        }
    ]

    [@addConfigurationSet
        scopeId=BLUEPRINT_CONFIGURATION_SCOPE
        id=referenceLookupType
        properties=properties
        attributes=[
            {
                "Names" : [ referenceLookupType ],
                "SubObjects" : true,
                "Children" : attributes
            }
        ]
    /]

    [@addConfigurationSet
        scopeId=LAYER_CONFIGURATION_SCOPE
        id=type
        properties=properties
        configuration=configuration
        attributes=attributes
    /]

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
    [#return getConfigurationSet(LAYER_CONFIGURATION_SCOPE, type)?has_content ]
[/#function]

[#-- Fetch configuration of a layer             --]
[#-- Assumes layer is expected to be configured --]
[#function getLayerConfiguration type="" ]
    [#if type?has_content]
        [#local layerConfig = getConfigurationSet(LAYER_CONFIGURATION_SCOPE, type) ]
        [#if layerConfig?has_content ]
            [#return layerConfig ]
        [#else]
            [@fatal
                message="Could not find layer configuration"
                detail=type
            /]
            [#return {} ]
        [/#if]
    [#else]
        [#local result = {}]
        [#list getConfigurationSets(LAYER_CONFIGURATION_SCOPE) as set]
            [#local result = mergeObjects(
                result,
                {
                    set.Id : {
                        "Attributes" : set.Attributes,
                        "Properties" : set.Properties,
                        "Configuration" : set.Configuration
                    }
                }
            )]
        [/#list]
        [#return result]
    [/#if]
[/#function]

[#-- Return the layer input filter attributes --]
[#function getLayerInputFilterAttributes type ]
    [#local attributeValue = (getLayerConfiguration(type).Configuration.InputFilterAttributes[0].Id)!"" ]
    [#return arrayIfContent(attributeValue, attributeValue) ]
[/#function]
