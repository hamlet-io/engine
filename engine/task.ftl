[#ftl]

[#-- tasks are executed in contracts --]
[#-- Each task should perform a specifc action to manage a deployment --]

[#assign taskConfiguration = {}]

[#-- Macros to assemble the component configuration --]
[#macro addTask type properties attributes ]
    [@internalMergeTaskConfiguration
        type=type
        configuration=
            {
                "Properties" : asArray(properties),
                "Attributes" : asArray(attributes)
            }
    /]
[/#macro]

[#function getTask type parameters ]
    [#local taskConfig = (taskConfiguration[type])!{} ]
    [#if data?has_content ]
        [#return
            {
                "Type" : type,
                "Parameters" : getCompositeObject(
                                    taskConfig.Attributes,
                                    parameters
                                )
            }
        ]
    [#else]
        [@fatal
            message="Attempt to add data for unknown task type"
            detail=type
        /]
    [/#if]
[/#function]

[#-------------------------------------------------------
-- Internal support functions for task processing      --
---------------------------------------------------------]

[#-- Helper macro - not for general use --]
[#macro internalMergeTaskConfiguration type configuration]
    [#assign referenceConfiguration =
        mergeObjects(
            referenceConfiguration,
            {
                type : configuration
            }
        )]
[/#macro]
