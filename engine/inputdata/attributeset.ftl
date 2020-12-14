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