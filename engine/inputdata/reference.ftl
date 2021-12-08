[#ftl]

[#---------------------------------------------
-- Public functions for reference data processing --
-----------------------------------------------]

[#-- Reference Data is extended dynamically by each reference Data type --]
[#assign referenceData = {}]

[#macro addReferenceData type base={} data={} ]
    [#if base?has_content]
        [@internalMergeReferenceData
            type=type
            data=base[getReferenceBlueprintKey(type)]!{}
        /]
    [#else]
        [@internalMergeReferenceData
            type=type
            data=data
        /]
    [/#if]
[/#macro]

[#function getAllReferenceData ]
    [#local result = {}]
    [#list getReferenceConfiguration()?keys as type ]
        [#local result += {
            type: getReferenceData(type)
        }]
    [/#list]
    [#return result]
[/#function]

[#function getReferenceData type ignoreMissing=false]
    [#if getReferenceConfiguration(type)?has_content]
        [#return (referenceData[getReferenceBlueprintKey(type)])!{} ]
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

[#macro includeReferences blueprint]
    [#list getReferenceConfiguration()?keys as id ]
        [@addReferenceData type=id base=blueprint /]
    [/#list]
[/#macro]

[#-------------------------------------------------------
-- Internal support functions for component processing --
---------------------------------------------------------]
[#macro internalMergeReferenceData type data={} ]
    [#local referenceConfig = (getReferenceConfiguration(type))!{} ]
    [#if referenceConfig?has_content ]
        [#if data?has_content ]
            [#list data as id,content ]

                [#local compositeData = getCompositeObject(referenceConfig.Attributes, content) ]
                [#assign referenceData =
                    mergeObjects(
                        referenceData,
                        {
                            getReferenceBlueprintKey(type): {
                                id : compositeData
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
