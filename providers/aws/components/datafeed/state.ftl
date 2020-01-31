[#ftl]

[#macro aws_datafeed_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local streamId = formatResourceId(AWS_KINESIS_FIREHOSE_STREAM_RESOURCE_TYPE, core.Id)]
    [#local streamName = core.FullName]

    [#local lgId = formatLogGroupId(core.Id)]
    [#assign componentState =
        {
            "Resources" : {
                "stream" : {
                    "Id" : streamId,
                    "Name" : streamName,
                    "Type" : AWS_KINESIS_FIREHOSE_STREAM_RESOURCE_TYPE,
                    "Monitored" : true
                },
                "role" : {
                    "Id" : formatResourceId(AWS_IAM_ROLE_RESOURCE_TYPE, core.Id),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
                }
            } +
            solution.Logging?then(
                {
                    "lg" : {
                        "Id" : lgId,
                        "Name" : core.FullAbsolutePath,
                        "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                        "IncludeInDeploymentState" : false
                    },
                    "backuplgstream" : {
                        "Id" : formatDependentResourceId(AWS_CLOUDWATCH_LOG_GROUP_STREAM_RESOURCE_TYPE, lgId, "backup"),
                        "Name" : "S3Delivery",
                        "Type" : AWS_CLOUDWATCH_LOG_GROUP_STREAM_RESOURCE_TYPE,
                        "IncludeInDeploymentState" : false
                    },
                    "streamlgstream" : {
                        "Id" : formatDependentResourceId(AWS_CLOUDWATCH_LOG_GROUP_STREAM_RESOURCE_TYPE, lgId, "stream"),
                        "Name" : "ElasticsearchDelivery",
                        "Type" : AWS_CLOUDWATCH_LOG_GROUP_STREAM_RESOURCE_TYPE,
                        "IncludeInDeploymentState" : false
                    }
                },
                {}
            ) +
            (solution.LogWatchers?has_content)?then(
                {
                    "subscriptionRole" : {
                        "Id" : formatResourceId(AWS_IAM_ROLE_RESOURCE_TYPE, core.Id, "subscription"),
                        "Type" : AWS_IAM_ROLE_RESOURCE_TYPE,
                        "IncludeInDeploymentState" : false
                    }
                },
                {}
            ),
            "Attributes" : {
                "STREAM_NAME" : getExistingReference(streamId),
                "STREAM_ARN" : getExistingReference(streamId, ARN_ATTRIBUTE_TYPE)
            },
            "Roles" : {
                "Outbound" : {
                    "default" : "produce",
                    "produce" : firehoseStreamProducePermission(streamId)
                },
                "Inbound" : {
                }
            }
        }
    ]
[/#macro]