[#ftl]

[#--
    Compute tasks define a common definition of a an action that a compute instance needs to complete
    The idea with compute tasks is to define a standard set of tasks that component developers
    can require for their components
    User defined extensions can then implement the tasks required to ensure that the component
    will work as expected
--]

[#-- Extension Scopes --]
[#-- Compute tasks work through the extensions mechanism --]
[#assign COMPUTETASK_EXTENSION_SCOPE = "computetask"]

[#assign computeTaskConfiguration = {}]

[#-- Macros to assemble the component configuration --]
[#macro addComputeTask type properties  ]
    [@internalMergeComputeTaskConfiguration
        type=type
        configuration=
            {
                "Properties" : asArray(properties)
            }
    /]
[/#macro]

[#function getComputeTaskTypes ]
    [#return computeTaskConfiguration?keys]
[/#function]

[#function getComputeTasks ]
    [#return computeTaskConfiguration]
[/#function]

[#function getOccurrenceComputeTaskConfig occurrence computeResourceId context compteTaskExtensions componentComputeTasks userComputeTasks ]

    [#local context = mergeObjects(
                        context,
                        {
                            "ComputeResourceId" : computeResourceId
                        }
                    )]

    [#local context = invokeExtensions(occurrence, context, {}, compteTaskExtensions, true, "deployment", "computetask")]

    [@validateRequiredComputeTasks
        computeTasks=(context.ComputeTasks)![]
        componentComputeTasks=componentComputeTasks
        userComputeTasks=userComputeTasks
    /]

    [#return (context.ComputeTaskConfig)!{}]
[/#function]

[#macro validateRequiredComputeTasks computeTasks componentComputeTasks userComputeTasks ]
    [#local missingComponentTasks = []]
    [#local missingUserTasks = []]

    [#list componentComputeTasks as componentComputeTask ]
        [#if ! (computeTasks?seq_contains(componentComputeTask))]
            [#local missingComponentTasks += [ componentComputeTask ]]
        [/#if]
    [/#list]

    [#list userComputeTasks as userComputeTask ]
        [#if ! (computeTasks?seq_contains(userComputeTasks))]
            [#local missingUserTasks += [ userComputeTask ]]
        [/#if]
    [/#list]

    [#if missingComponentTasks?has_content || missingUserTasks?has_content ]
        [@fatal
            message="Required component compute task was not included"
            detail="Add a computeInitConfigSection to an extension which will perform the required task"
            context={
                "CurrentComputeTasks" : computeTasks,
                "MissingComponentTasks" : missingComponentTasks,
                "MissingUserTasks" : missingUserTasks
            }
        /]
    [/#if]
[/#macro]
[#-------------------------------------------------------
-- Internal support functions for task processing      --
---------------------------------------------------------]

[#-- Helper macro - not for general use --]
[#macro internalMergeComputeTaskConfiguration type configuration]
    [#assign computeTaskConfiguration =
        mergeObjects(
            computeTaskConfiguration,
            {
                type : configuration
            }
        )]
[/#macro]
