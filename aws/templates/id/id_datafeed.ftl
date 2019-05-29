[#-- datafeed --]

[#-- Components --]
[#assign DATAFEED_COMPONENT_TYPE = "datafeed" ]

[#assign componentConfiguration +=
    {
        DATAFEED_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "A service which feeds data into the ES index currently based on kineses data firehose"
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
                    "Names" : "ElasticSearch",
                    "Children" : [
                        {
                            "Names" : "IndexPrefix",
                            "Type" : STRING_TYPE,
                            "Description" : "The prefix applied to generate the index name ( if not using roll over this will be the index name)",
                            "Mandatory" : true
                        },
                        {
                            "Names" : "IndexRotation",
                            "Type" : STRING_TYPE,
                            "Description" : "When to rotate the index ( the timestamp will be appended to the indexprefix)",
                            "Values" : [ "NoRotation", "OneDay", "OneHour", "OneMonth", "OneWeek" ],
                            "Default" : "OneMonth"
                        },
                        {
                            "Names" : "DocumentType",
                            "Type" : STRING_TYPE,
                            "Description" : "The document type used when creating the document",
                            "Mandatory" : true
                        }
                    ]
                },
                {
                    "Names" : "Buffering",
                    "Description" : "How long data should be bufferred before being deliverd to ES",
                    "Children" : [
                        {
                            "Names" : "Interval",
                            "Type" : NUMBER_TYPE,
                            "Description" : "The time in seconds before data should be delivered",
                            "Default" : 60
                        },
                        {
                            "Names" : "Size",
                            "Type" : NUMBER_TYPE,
                            "Description" : "The size in MB before data should be delivered",
                            "Default" : 1
                        }
                    ]
                },
                {
                    "Names" : "Logging",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Encrypted",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                }
                {
                    "Names" : "Backup",
                    "Children" : [
                        {
                            "Names" : "FailureDuration",
                            "Type" : NUMBER_TYPE,
                            "Description" : "The time in seconds that the data feed will attempt to deliver the data before it is sent to backup",
                            "Default" : 3600
                        },
                        {
                            "Names" : "Policy",
                            "Type" : STRING_TYPE,
                            "Description" : "The backup policy to apply to records",
                            "Values" : [ "AllDocuments", "FailedDocumentsOnly" ],
                            "Default" : "FailedDocumentsOnly"
                        }
                    ]   
                },
                {
                    "Names" : "Destination",
                    "Children" : [
                        {
                            "Names" : "Link",
                            "Children" : linkChildrenConfiguration,
                            "Mandatory" : true
                        }
                    ]
                }
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "Alerts",
                    "Subobjects" : true,
                    "Children" : alertChildrenConfiguration
                },
                {
                    "Names" : "LogWatchers",
                    "Subobjects" : true,
                    "Children" : logWatcherChildrenConfiguration
                }
            ]
        }
    }
]

[#function getDataFeedState occurrence ]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local streamId = formatResourceId(AWS_KINESIS_FIREHOSE_STREAM_RESOURCE_TYPE, core.Id)]
    [#local streamName = core.FullName]

    [#local lgId = formatLogGroupId(core.Id)]
    [#return
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
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                }
            } + 
            solution.Logging?then(
                {
                    "lg" : {
                        "Id" : lgId,
                        "Name" : core.FullAbsolutePath,
                        "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                    },
                    "backuplgstream" : {
                        "Id" : formatDependentResourceId(AWS_CLOUDWATCH_LOG_GROUP_STREAM_RESOURCE_TYPE, lgId, "backup"),
                        "Name" : "S3Delivery",
                        "Type" : AWS_CLOUDWATCH_LOG_GROUP_STREAM_RESOURCE_TYPE
                    },
                    "streamlgstream" : {
                        "Id" : formatDependentResourceId(AWS_CLOUDWATCH_LOG_GROUP_STREAM_RESOURCE_TYPE, lgId, "stream"),
                        "Name" : "ElasticsearchDelivery",
                        "Type" : AWS_CLOUDWATCH_LOG_GROUP_STREAM_RESOURCE_TYPE
                    }
                },
                {}
            ) + 
            (solution.LogWatchers?has_content)?then(
                {
                    "subscriptionRole" : {
                        "Id" : formatResourceId(AWS_IAM_ROLE_RESOURCE_TYPE, core.Id, "subscription"),
                        "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
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
[/#function]