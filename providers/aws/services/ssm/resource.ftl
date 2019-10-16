[#ftl]

[#assign AWS_SSM_DOCUMENT_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]

[#assign AWS_SSM_MAINTENANCE_WINDOW_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]
[@addOutputMapping 
    provider=AWS_PROVIDER
    resourceType=AWS_SSM_DOCUMENT_RESOURCE_TYPE
    mappings=AWS_SSM_DOCUMENT_OUTPUT_MAPPINGS
/]
[@addOutputMapping 
    provider=AWS_PROVIDER
    resourceType=AWS_SSM_MAINTENANCE_WINDOW_RESOURCE_TYPE
    mappings=AWS_SSM_MAINTENANCE_WINDOW_OUTPUT_MAPPINGS
/]

[#macro createSSMDocument id content tags documentType="" dependencies="" ]
    [@cfResource
        id=id
        type="AWS::SSM::Document"
        properties=
            {
                "Content" : content,
                "DocumentType" : documentType,
                "Tags" : tags
            }
        outputs=SSM_DOCUMENT_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]

[#macro createSSMMaintenanceWindow id
    name
    schedule
    durationHours
    cutoffHours
    tags=[]
    scheduleTimezone="Etc/UTC"
    dependencies=""
]
    [@cfResource
        id=id
        type="AWS::SSM::MaintenanceWindow"
        properties=
            {
                "Name" : name,
                "AllowUnassociatedTargets" : false,
                "Schedule" : schedule,
                "Duration" : durationHours,
                "Cutoff" : cutoffHours,
                "Tags" : tags,
                "ScheduleTimezone" : scheduleTimezone
            }
        outputs=AWS_SSM_MAINTENANCE_WINDOW_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]


[#macro createSSMMaintenanceWindowTarget id
    name
    windowId
    targets
    dependencies=""
]
    [@cfResource
        id=id
        type="AWS::SSM::MaintenanceWindowTarget"
        properties=
            {
                "Name" : name,
                "OwnerInformation" : name,
                "WindowId" : getReference(windowId),
                "ResourceType" : "INSTANCE",
                "Targets" : targets
            }
        dependencies=dependencies
    /]
[/#macro]

[#function getSSMWindowTargets tags=[] instanceIds=[] usePlaceholderInstance=false ]
    [#local targets = [] ]
    [#if usePlaceholderInstance ]
        [#local targets += [
            {
                "Key" : "InstanceIds",
                "Values" : asArray("i-00000000000000000")
            }
        ]]
    [#else]
        [#list tags as tag ]
            [#local formattedValues = []]
            [#list asArray(tag.Values) as value ]
                [#local formattedValues +=  [( "\"" + value + "\"" )] ]
            [/#list]
            [#local targets += [
                {
                    "Key" : "\"tag:" + tag.Key + "\"",
                    "Values" : asArray(formattedValues)
                }
            ]]
        [/#list]

        [#if instanceIds?has_content ]
            [#local targets += [
                {
                    "Key" : "InstanceIds",
                    "Values" : asArray(instanceIds)
                }
            ]]
        [/#if]
    [/#if]
    [#return targets]
[/#function]

[#macro createSSMMaintenanceWindowTask id
    name
    targets
    serviceRoleId
    windowId
    taskId
    taskType
    taskParameters
    priority=10
    maxErrors=0
    maxConcurrency=1
    dependencies=""
]

    [#local taskType = taskType?upper_case ]
    [@cfResource
        id=id
        type="AWS::SSM::MaintenanceWindowTask"
        properties=
            {
                "Name" : name,
                "MaxErrors" : maxErrors,
                "ServiceRoleArn" : getReference(serviceRoleId, ARN_ATTRIBUTE_TYPE),
                "WindowId" : getReference(windowId),
                "Priority" : priority,
                "MaxConcurrency" : maxConcurrency,
                "Targets" : targets,
                "TaskArn" : ( taskType == "AUTOMATION" )?then(
                                taskId,
                                getReference(taskId, ARN_ATTRIBUTE_TYPE)
                ),
                "TaskType" : taskType,
                "TaskInvocationParameters" : {} +
                    (taskType == "AUTOMATION" )?then(
                        {
                            "MaintenanceWindowAutomationParameters" : taskParameters
                        },
                        {}
                    ) +
                    (taskType == "LAMBDA" )?then(
                        {
                            "MaintenanceWindowLambdaParameters" : taskParameters
                        },
                        {}
                    )
            }
        dependencies=dependencies
    /]
[/#macro]


[#function getSSMWindowAutomationTaskParameters parameters documentVersion="" ]
    [#return
        {
            "Parameters" : parameters
        } +
        attributeIfContent(
            "DocumentVersion",
            documentVersion
        )]
[/#function]

[#function getSSMWindowLambdaTaskParamters payload clientContext="" lambdaQualifer="" ]
    [#return
        {
            "Payload" : payload
        } +
        attributeIfContent(
            "Qualifier",
            lambdaQualifer
        ) +
        attributeIfContent(
            "ClientContext",
            clientContext
        )]
[/#function]