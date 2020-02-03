[#ftl]

[#macro aws_sqs_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]

    [#if core.External!false]
        [#local id = occurrence.State.Attributes["ARN"]!"" ]
        [#assign componentState =
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
        [#local solution = occurrence.Configuration.Solution]

        [#local id = formatResourceId(AWS_SQS_RESOURCE_TYPE, core.Id) ]
        [#local name = core.FullName ]

        [#local dlqId = formatDependentResourceId(AWS_SQS_RESOURCE_TYPE, id, "dlq") ]
        [#local dlqName = formatName(name, "dlq")]

        [#local dlqRequired =
            isPresent(solution.DeadLetterQueue) ||
            ((environmentObject.Operations.DeadLetterQueue.Enabled)!false)]

        [#assign componentState =
            {
                "Resources" : {
                    "queue" : {
                        "Id" : id,
                        "Name" : name,
                        "Type" : AWS_SQS_RESOURCE_TYPE,
                        "Monitored" : true
                    }
                } +
                dlqRequired?then(
                    {
                        "dlq" : {
                            "Id" : dlqId,
                            "Name" : dlqName,
                            "Type" : AWS_SQS_RESOURCE_TYPE,
                            "Monitored" : true
                        }
                    },
                    {}
                ),
                "Attributes" : {
                    "NAME" : getExistingReference(id, NAME_ATTRIBUTE_TYPE),
                    "URL" : getExistingReference(id, URL_ATTRIBUTE_TYPE),
                    "PRODUCT_URL" : getExistingReference(id, URL_ATTRIBUTE_TYPE)?replace("https://", "sqs://"),
                    "ARN" : getExistingReference(id, ARN_ATTRIBUTE_TYPE),
                    "REGION" : getExistingReference(id, REGION_ATTRIBUTE_TYPE)!regionId
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
[/#macro]
