[#ftl]

[#-- Global Metaparameter Object --]
[#assign metaparameterConfiguration = {}]

[#macro addMetaparameter type pluralType properties attributes]
    [#local configuration = {
        "Type" : {
            "Singular"  : type,
            "Plural"    : pluralType
        },
        "Properties" : asArray(properties),
        "Attributes" : asArray(attributes)}]

    [@internalMergeMetaparameterConfiguration
        type=type
        configuration=configuration
    /]
[/#macro]

[#-----------------------------------------------------
-- Internal support functions for metaparameter processing --
-------------------------------------------------------]

[#macro internalMergeMetaparameterConfiguration type configuration]
    [#assign metaparameterConfiguration =
        mergeObjects(
            metaparameterConfiguration,
            {
                type : configuration
            }
        )]
[/#macro]