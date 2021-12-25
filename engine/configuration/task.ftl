[#ftl]

[#-- tasks are executed in contracts --]
[#-- Each task should perform a specifc action within a contract --]
[#assign TASK_CONFIGURATION_SCOPE = "Task" ]

[@addConfigurationScope
    id=TASK_CONFIGURATION_SCOPE
    description="Tasks definiitions to perform configuration of compute instances"
/]

[#-- Macros to assemble the component configuration --]
[#macro addTask type properties attributes ]

    [@addConfigurationSet
        scopeId=TASK_CONFIGURATION_SCOPE
        id=type
        properties=properties
        attributes=attributes
    /]
[/#macro]

[#function getTask type parameters ]
    [#local taskConfig = getConfigurationSet(TASK_CONFIGURATION_SCOPE, type)]

    [#if taskConfig?has_content ]
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
