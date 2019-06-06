[#-- SQS --]

[#-- Resources --]
[#assign AWS_SQS_RESOURCE_TYPE = "sqs" ]

[#-- Components --]
[#assign SQS_COMPONENT_TYPE = "sqs"]

[#assign componentConfiguration +=
    {
        SQS_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "Managed worker queue engine"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "DelaySeconds",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "MaximumMessageSize",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "MessageRetentionPeriod",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "ReceiveMessageWaitTimeSeconds",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "DeadLetterQueue",
                    "Children" : [
                        {
                            "Names" : "MaxReceives",
                            "Type" : NUMBER_TYPE,
                            "Default" : 0
                        }
                    ]
                },
                {
                    "Names" : "VisibilityTimeout",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration
                },
                {
                    "Names" : "Alerts",
                    "Subobjects" : true,
                    "Children" : alertChildrenConfiguration
                }
            ]
        }
    }]

[#macro aws_sqs_cf_state occurrence parent={} baseState={}  ]
    [#assign componentState = getSQSState(occurrence, baseState)]
[/#macro]

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
        [#local solution = occurrence.Configuration.Solution]

        [#local id = formatResourceId(AWS_SQS_RESOURCE_TYPE, core.Id) ]
        [#local name = core.FullName ]

        [#local dlqId = formatDependentResourceId(AWS_SQS_RESOURCE_TYPE, id, "dlq") ]
        [#local dlqName = formatName(name, "dlq")]

        [#assign dlqRequired =
            isPresent(solution.DeadLetterQueue) ||
            ((environmentObject.Operations.DeadLetterQueue.Enabled)!false)]

        [#return
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
