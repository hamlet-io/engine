[#-- SQS --]

[#-- Resources --]
[#assign AWS_SQS_RESOURCE_TYPE = "sqs" ]

[#-- Components --]
[#assign SQS_COMPONENT_TYPE = "sqs"]

[#assign componentConfiguration +=
    {
        SQS_COMPONENT_TYPE : [
            "DelaySeconds",
            "MaximumMessageSize",
            "MessageRetentionPeriod",
            "ReceiveMessageWaitTimeSeconds",
            {
                "Name" : "DeadLetterQueue",
                "Children" : [
                    {
                        "Name" : "MaxReceives",
                        "Default" : 0
                    },
                    {
                        "Name" : "Enabled",
                        "Default" : true
                    }
                ]
            },
            "VisibilityTimeout"
        ]
    }]
    
[#function getSQSState occurrence]
    [#local core = occurrence.Core]

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
                    "produce" : sqsProducePermission(id),
                    "consume" : sqsConsumePermission(id)
                }
            }
        }
    ]
[/#function]
