[#ftl]

[#macro aws_topic_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local topicId = formatResourceId(AWS_SNS_TOPIC_RESOURCE_TYPE, core.Id)]

    [#assign componentState =
        {
            "Resources" : {
                "topic" : {
                    "Id" : topicId,
                    "Name" : core.FullName,
                    "Type" : AWS_SNS_TOPIC_RESOURCE_TYPE,
                    "Monitored" : true
                }
            },
            "Attributes" : {
                "ARN" : getExistingReference(topicId, ARN_ATTRIBUTE_TYPE),
                "NAME" : getExistingReference(topicId, NAME_ATTRIBUTE_TYPE)
            },
            "Roles" : {
                "Inbound" : {
                    "invoke" : {
                        "Principal" : "sns.amazonaws.com",
                        "SourceArn" : getReference(topicId,ARN_ATTRIBUTE_TYPE)
                    }
                },
                "Outbound" : {
                    "default" : "publish",
                    "publish" : snsPublishPermission(topicId)
                }
            }
        }
    ]
[/#macro]

[#macro aws_topicsubscription_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#assign componentState =
        {
            "Resources" : {
                "subscription" : {
                    "Id" : formatResourceId(AWS_SNS_SUBSCRIPTION_RESOURCE_TYPE, core.Id),
                    "Type" : AWS_SNS_SUBSCRIPTION_RESOURCE_TYPE
                }
            },
            "Attributes" : {
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]
