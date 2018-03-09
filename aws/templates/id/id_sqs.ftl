[#-- SQS --]

[#assign SQS_RESOURCE_TYPE = "sqs" ]

[#assign componentConfiguration +=
    {
        "sqs" : [
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

    [#local id = formatResourceId(SQS_RESOURCE_TYPE, core.Id) ]
    [#local name = formatSegmentFullName(core.Name) ]

    [#local dlqId = formatDependentResourceId(SQS_RESOURCE_TYPE, id, "dlq") ]
    [#local dlqName = formatName(name, "dlq")]

    [#return
        {
            "Resources" : {
                "queue" : {
                    "Id" : id,
                    "Name" : name
                },
                "dlq" : {
                    "Id" : dlqId,
                    "Name" : dlqName
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
