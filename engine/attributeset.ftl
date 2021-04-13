[#ftl]

[#-- Global AttributeSet Object --]
[#assign attributeSetConfiguration = {}]

[#macro addAttributeSet type pluralType properties attributes]
    [#local configuration = {
        "Type" : {
            "Singular"  : type,
            "Plural"    : pluralType
        },
        "Properties" : asArray(properties),
        "Attributes" : asArray(attributes)}]

    [@internalMergeAttributeSetConfiguration
        type=type
        configuration=configuration
    /]
[/#macro]

[#macro addExtendedAttributeSet baseType provider type pluralType properties attributes ]
    [#local baseAttributeSetConfig = getAttributeSet(baseType)]
    [#if ! (baseAttributeSetConfig?has_content)  ]
        [@fatal
            message="Could not find base attribute set to extend"
            detail="Ensure the attribute set is available or you are using a provider that is available"
            context={
                "BaseType" : baseType,
                "Type" : type,
                "Provider" : provider
            }
        /]
    [/#if]

    [#local extendedAttributes = extendAttributes(baseAttributeSetConfig.Attributes, attributes, provider)]

    [@addAttributeSet
        type=type
        pluralType=pluralType
        properties=properties
        attributes=extendedAttributes
    /]
[/#macro]

[#function getAttributeSet type ]
    [#return (attributeSetConfiguration[type])!{} ]
[/#function]

[#-----------------------------------------------------
-- Internal support functions for AttributeSet processing --
-------------------------------------------------------]

[#macro internalMergeAttributeSetConfiguration type configuration]
    [#assign attributeSetConfiguration =
        mergeObjects(
            attributeSetConfiguration,
            {
                type : configuration
            }
        )]
[/#macro]
