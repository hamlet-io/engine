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
[#assign COMPUTETASK_CONFIGURATION_SCOPE = "ComputeTask" ]

[@addConfigurationScope
    id=COMPUTETASK_CONFIGURATION_SCOPE
    description="Tasks definiitions to perform configuration of compute instances"
/]

[#-- Macros to assemble the component configuration --]
[#macro addComputeTask type properties  ]
    [@addConfigurationSet
        scopeId=COMPUTETASK_CONFIGURATION_SCOPE
        id=type
        attributes=[]
        properties=properties
    /]
[/#macro]

[#function getComputeTaskTypes ]
    [#return getConfigurationSetIds(COMPUTETASK_CONFIGURATION_SCOPE) ]
[/#function]

[#function getComputeTasks ]
    [#local result = {}]

    [#list getConfigurationSets(COMPUTETASK_CONFIGURATION_SCOPE) as configurationSet]
        [#local result = mergeObjects(
            result, {
                configurationSet.Id : {
                    "Properties" : configurationSet.Properties,
                    "Attributes" : configurationSet.Attributes
                }
            }
        )]
    [/#list]

    [#return result]
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
