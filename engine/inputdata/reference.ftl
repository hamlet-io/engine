[#ftl]

[#---------------------------------------------
-- Public functions for reference data processing --
-----------------------------------------------]

[#-- Reference Data is extended dynamically by each reference Data type --]
[#assign referenceConfiguration = {} ]
[#assign referenceData = {}]

[#-- Macros to assemble the component configuration --]
[#macro addReference type pluralType properties attributes ]
    [@internalMergeReferenceConfiguration
        type=type
        configuration=
            {
                "Type" : {
                    "Singular"  : type,
                    "Plural"    : pluralType
                },
                "Properties" : asArray(properties),
                "Attributes" : asArray(attributes)
            }
    /]
[/#macro]

[#macro addReferenceData type base={} data={} ]
    [#if base?has_content]
        [@internalMergeReferenceData
            type=type
            data=base[(referenceConfiguration[type].Type.Plural)!""]!{}
        /]
    [#else]
        [@internalMergeReferenceData
            type=type
            data=data
        /]
    [/#if]
[/#macro]

[#function getReferenceData type ignoreMissing=false]
    [#local referenceConfig = referenceConfiguration[type]!{}]
    [#if referenceConfig?has_content]
        [#return (referenceData[(referenceConfig.Type.Plural)])!{} ]
    [#else]
        [#if !ignoreMissing]
            [@fatal
                message="Attempt to access data for unknown reference data type"
                detail=type
            /]
        [/#if]
        [#return {} ]
    [/#if]
[/#function]

[#-------------------------------------------------------
-- Internal support functions for component processing --
---------------------------------------------------------]

[#-- Helper macro - not for general use --]
[#macro internalMergeReferenceConfiguration type configuration]
    [#assign referenceConfiguration =
        mergeObjects(
            referenceConfiguration,
            {
                type : configuration
            }
        )]
    [#if ! (referenceData?keys)?seq_contains(configuration.Type.Plural) ]
        [#assign referenceData = mergeObjects( { configuration.Type.Plural : {} } ) ]
    [/#if]
[/#macro]

[#macro internalMergeReferenceData type data={} ]
    [#local referenceConfig = (referenceConfiguration[type])!{} ]
    [#if referenceConfig?has_content ]
        [#if data?has_content ]
            [#list data as id,content ]
                [#assign referenceData =
                    mergeObjects(
                        referenceData,
                        {
                            referenceConfig.Type.Plural: {
                                id : getCompositeObject( referenceConfig.Attributes, content)
                            }
                        }
                    )]
            [/#list]
        [/#if]
    [#else]
        [@fatal
            message="Attempt to add data for unknown reference data type"
            detail=type
        /]
    [/#if]
[/#macro]