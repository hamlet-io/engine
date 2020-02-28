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

    [#local attributes =
        [
            "InhibitEnabled"
        ] +
        taskConfig.Attributes
    ]

    [#if taskConfig?has_content ]
        [#return
            {
                "Type" : type,
                "Parameters" : getCompositeObject(
                                    attributes,
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
    [#assign taskConfiguration =
        mergeObjects(
            taskConfiguration,
            {
                type : configuration
            }
        )]
[/#macro]
