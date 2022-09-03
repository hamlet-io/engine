[#ftl]


[#assign REFERENCE_CONFIGURATION_SCOPE = "Reference" ]

[@addConfigurationScope
    id=REFERENCE_CONFIGURATION_SCOPE
    description="Data that provides shared references or common properties"
/]

[#-- Macros to assemble the component configuration --]
[#macro addReference type pluralType properties attributes ]

    [@addConfigurationSet
        scopeId=BLUEPRINT_CONFIGURATION_SCOPE
        id=pluralType
        properties=properties
        attributes=[
            {
                "Names" : [ pluralType ],
                "SubObjects" : true,
                "Children" : attributes
            }
        ]
    /]

    [#local referenceProperties = combineEntities(
            properties
                ?filter(x -> x.Type != "BlueprintKey" ),
            [
                {
                    "Type" : "BlueprintKey",
                    "Value" : pluralType
                }
            ]
        )]

    [@addConfigurationSet
        scopeId=REFERENCE_CONFIGURATION_SCOPE
        id=type
        properties=referenceProperties
        attributes=expandBaseCompositeConfiguration(attributes)
    /]
[/#macro]

[#function getReferenceBlueprintKey type ]
    [#local configSet = getConfigurationSets(REFERENCE_CONFIGURATION_SCOPE)?filter( x -> x.Id == type)[0] ]
    [#return ((configSet["Properties"])?filter( x -> x.Type == "BlueprintKey")[0]["Value"])!"" ]
[/#function]

[#function getReferenceConfiguration type="" ]
    [#if type?has_content]
        [#return getConfigurationSet(REFERENCE_CONFIGURATION_SCOPE, type)]
    [#else]
        [#local result = {}]
        [#list getConfigurationSets(REFERENCE_CONFIGURATION_SCOPE) as set]
            [#local result = mergeObjects(result, { set.Id : { "Attributes" : set.Attributes, "Properties" : set.Properties }} )]
        [/#list]
        [#return result]
    [/#if]
[/#function]
