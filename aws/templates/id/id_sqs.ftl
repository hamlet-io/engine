[#-- SQS --]

[#-- Resources --]
[#assign AWS_SQS_RESOURCE_TYPE = "sqs" ]

[#-- Components --]
[#assign SQS_COMPONENT_TYPE = "sqs"]

[#assign componentConfiguration +=
    {
        SQS_COMPONENT_TYPE : [
            {
                "Name" : "DelaySeconds",
                "Type" : NUMBER_TYPE
            },
            {
                "Name" : "MaximumMessageSize",
                "Type" : NUMBER_TYPE
            },
            {
                "Name" : "MessageRetentionPeriod",
                "Type" : NUMBER_TYPE
            },
            {
                "Name" : "ReceiveMessageWaitTimeSeconds",
                "Type" : NUMBER_TYPE
            },
            {
                "Name" : "DeadLetterQueue",
                "Children" : [
                    {
                        "Name" : "MaxReceives",
                        "Type" : NUMBER_TYPE,
                        "Default" : 0
                    }
                ]
            },
            {
                "Name" : "VisibilityTimeout",
                "Type" : NUMBER_TYPE
            }
        ]
    }]
    
[#function getSQSState occurrence baseState]
    [#local core = occurrence.Core]

    [#if core.External!false]
        [#local id = baseState.Attributes["ARN"]!"" ]
        [#return
            baseState +
            valueIfContent(
                {
                    "Roles" : {
                        "Inbound" : {},
                        "Outbound" : {
                            "all" : sqsAllPermission(id),
                            "event" : sqsConsumePermission(id),
                            "produce" : sqsProducePermission(id),
                            "consume" : sqsConsumePermission(id)
                        }
                    }
                },
                id,
                {
                    "Roles" : {
                        "Inbound" : {},
                        "Outbound" : {}
                    }
                }
            )
        ]
    [#else]
        [#local id = formatResourceId(AWS_SQS_RESOURCE_TYPE, core.Id) ]
        [#local name = core.FullName ]
    
        [#local dlqId = formatDependentResourceId(AWS_SQS_RESOURCE_TYPE, id, "dlq") ]
        [#local dlqName = formatName(name, "dlq")]
    
        [#return
            {
                "Resources" : {
                    "queue" : {
                        "Id" : id,
                        "Name" : name,
                        "Type" : AWS_SQS_RESOURCE_TYPE
                    },
                    "dlq" : {
                        "Id" : dlqId,
                        "Name" : dlqName,
                        "Type" : AWS_SQS_RESOURCE_TYPE
                    }
                },
                "Attributes" : {
                    "NAME" : getExistingReference(id, NAME_ATTRIBUTE_TYPE),
                    "URL" : getExistingReference(id, URL_ATTRIBUTE_TYPE),
                    "ARN" : getExistingReference(id, ARN_ATTRIBUTE_TYPE),
                    "REGION" : regionId
                },
                "Roles" : {
                    "Inbound" : {},
                    "Outbound" : {
                        "all" : sqsAllPermission(id),
                        "event" : sqsConsumePermission(id),
                        "produce" : sqsProducePermission(id),
                        "consume" : sqsConsumePermission(id)
                    }
                }
            }
        ]
    [/#if]
[/#function]
