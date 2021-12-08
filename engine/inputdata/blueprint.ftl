[#ftl]

[#-- Global Blueprint Object --]
[#assign blueprintObject = {}]

[#macro addBlueprint blueprint={} ]
    [#if blueprint?has_content ]
        [@internalMergeBlueprint
            base=blueprintObject
            blueprint=blueprint
        /]
    [/#if]
[/#macro]

[#macro rebaseBlueprint base={} ]
    [#if base?has_content ]
        [@internalMergeBlueprint
            base=base
            blueprint=blueprintObject
        /]
    [/#if]
[/#macro]

[#function getBlueprintConfiguration ]
    [#local attributes = []]

    [#-- Layers --]
    [#local layerChildren = []]
    [#list getLayerConfiguration() as layer,layerConfig]
        [#local layerChildren += [
            {
                "Names" : layerConfig.Configuration.ReferenceLookupType,
                "SubObjects" : true,
                "Children" : layerConfig.Attributes
            },
            {
                "Names" : layer,
                "Children" : layerConfig.Attributes
            }
        ]]
    [/#list]

    [#-- Components --]
    [@includeAllComponentDefinitionConfiguration
        SHARED_PROVIDER
        getLoaderProviders()
    /]

    [#local componentChildren = []]
    [#local subComponentNames =
        asFlattenedArray(
            componentConfiguration
            ?keys
            ?filter(c -> componentConfiguration[c].Components??)
            ?map(c -> componentConfiguration[c].Components)
        )?map(c -> c.Component)]

    [#list componentConfiguration as component,config]

        [#-- Skip any subComponents --]
        [#if !(subComponentNames?seq_contains(component))]
            [#local attrs = []]
            [#list config["ResourceGroups"]?values as resourceGroupConfig]
                [#local attrs += asFlattenedArray(resourceGroupConfig.Attributes?values)]
            [/#list]

            [#-- Include subComponents as valid Attribute children --]
            [#local components = []]
            [#if config.Components??]
                [#list config.Components as child]
                    [#local components += [{
                        "Names" : child.Component,
                        "SubObjects" : true,
                        "Children" : asFlattenedArray(componentConfiguration[child.Type]["ResourceGroups"]["default"].Attributes?values)
                    }] ]
                [/#list]
            [/#if]

            [#local componentChildren += [
                {
                    "Names" : component,
                    "Children" : combineEntities(attrs, components, ADD_COMBINE_BEHAVIOUR)
                }
            ]]
        [/#if]

    [/#list]

    [#-- Reference Data --]
    [#local referenceChildren = []]
    [#list getReferenceConfiguration() as type,referenceConfig]

        [#if getReferenceBlueprintKey(type) == "CertificateBehaviours"]
            [#local referenceChildren += [
                {
                    "Names" : getReferenceBlueprintKey(type),
                    "SubObjects" : false,
                    "Children" : referenceConfig.Attributes
                }
            ]]
        [#else]
            [#local referenceChildren += [
                {
                    "Names" : getReferenceBlueprintKey(type),
                    "SubObjects" : true,
                    "Children" : referenceConfig.Attributes
                }
            ]]
        [/#if]
    [/#list]

    [#local certChildren = [
        {
            "Names" : "Certificates",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Domain",
                    "Types" : STRING_TYPE
                }
            ]
        }
    ]]

    [#local domainChildren = [
        {
            "Names" : "Domains",
            "Children" : [
                {
                    "Names" : "*",
                    "Types" : OBJECT_TYPE,
                    "Children" : domainChildConfiguration
                },
                {
                    "Names" : "Validation",
                    "Types" : STRING_TYPE
                }
            ]
        }
    ]]

    [#return asFlattenedArray(
            [
                {
                    "Names" : "Tiers",
                    "SubObjects" : true,
                    "Children" : [
                        {
                            "Names" : "Components",
                            "SubObjects" : true,
                            "Children" : componentChildren
                        },
                        {
                            "Names" : "Network",
                            "Children" : [
                                {
                                    "Names" : "Link",
                                    "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                                },
                                {
                                    "Names" : "RouteTable",
                                    "Types" : STRING_TYPE
                                },
                                {
                                    "Names" : "NetworkACL",
                                    "Types" : STRING_TYPE
                                }
                            ]
                        }
                    ]
                }
            ] +
            referenceChildren +
            layerChildren +
            certChildren +
            domainChildren
        )]
[/#function]

[#-----------------------------------------------------
-- Internal support functions for blueprint processing --
-------------------------------------------------------]

[#macro internalMergeBlueprint base blueprint ]
    [#assign blueprintObject =
        mergeObjects(
            base,
            blueprint
        )
    ]
[/#macro]
