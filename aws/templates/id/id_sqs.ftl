[#-- SQS --]

[#assign SQS_RESOURCE_TYPE = "sqs" ]

[#function formatSQSId ids...]
    [#return formatResourceId(
                SQS_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentSQSId resourceId extensions...]
    [#return formatDependentResourceId(
                SQS_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatComponentSQSId tier component extensions...]
    [#return formatComponentResourceId(
                SQS_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

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
    [#local id = formatComponentSQSId(occurrence.Tier, occurrence.Component, occurrence)]

    [#return
        {
            "Resources" : {
                "primary" : {
                    "Id" : id
                }
            },
            "Attributes" : {
                "NAME" : getExistingReference(id, NAME_ATTRIBUTE_TYPE),
                "URL" : getExistingReference(id, URL_ATTRIBUTE_TYPE),
                "ARN" : getExistingReference(id, ARN_ATTRIBUTE_TYPE),
                "REGION" : regionId
            }
        }
    ]
[/#function]
