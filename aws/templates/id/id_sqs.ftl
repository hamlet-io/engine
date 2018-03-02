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

    [#local id =
        formatComponentResourceId(
            SQS_RESOURCE_TYPE,
            occurrence.Core.Tier,
            occurrence.Core.Component,
            occurrence) ]
    [#local name = (core.Component.Name != "SQS")?then(
                            formatName(
                                core.Component.Name,
                                occurrence),
                            formatName(
                                productName,
                                segmentName,
                                componentName,
                                occurrence))]

    [#local dlqId = formatDependentResourceId(SQS_RESOURCE_TYPE, id, "dlq") ]
    [#local dlqName = formatName(name, "dlq")]

    [#return
        {
            "Resources" : {
                "primary" : {
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
