[#ftl]

[#assign KINESIS_FIREHOSE_STREAM_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "Attribute" : "Arn"
        }
    }
]

[@addOutputMapping
    provider=AWS_PROVIDER
    resourceType=AWS_KINESIS_FIREHOSE_STREAM_RESOURCE_TYPE
    mappings=KINESIS_FIREHOSE_STREAM_OUTPUT_MAPPINGS
/]

[#assign metricAttributes +=
    {
        AWS_KINESIS_FIREHOSE_STREAM_RESOURCE_TYPE : {
            "Namespace" : "AWS/Firehose",
            "Dimensions" : {
                "DeliveryStreamName" : {
                    "Output" : REFERENCE_ATTRIBUTE_TYPE
                }
            }
        }
    }
]


[#macro createFirehoseStream id name destination dependencies="" ]
    [@cfResource
        id=id
        type="AWS::KinesisFirehose::DeliveryStream"
        properties=
            {
                "DeliveryStreamName" : name
            } +
            destination
        outputs=KINESIS_FIREHOSE_STREAM_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]

[#function getFirehoseStreamESDestination
        bufferInterval
        bufferSize
        esDomain
        roleId
        indexName
        indexRotation
        documentType
        retryDuration
        backupPolicy
        backupS3Destination
        loggingConfiguration
        lambdaProcessor ]

    [#return
        {
            "ElasticsearchDestinationConfiguration" : {
                "BufferingHints" : {
                    "IntervalInSeconds" : bufferInterval,
                    "SizeInMBs" : bufferSize
                },
                "DomainARN" : getArn(esDomain, true),
                "IndexName" : indexName,
                "IndexRotationPeriod" : indexRotation,
                "TypeName" : documentType,
                "RetryOptions" : {
                    "DurationInSeconds" : retryDuration
                },
                "RoleARN" : getReference(roleId, ARN_ATTRIBUTE_TYPE),
                "S3BackupMode" : backupPolicy,
                "S3Configuration" : backupS3Destination,
                "CloudWatchLoggingOptions" : loggingConfiguration
            } +
            attributeIfContent(
                "ProcessingConfiguration",
                lambdaProcessor,
                {
                    "Enabled" : true,
                    "Processors" : asArray(lambdaProcessor)
                }
            )
        }
    ]
[/#function]

[#function getFirehoseStreamBackupS3Destination
        bucketId
        bucketPrefix
        bufferInterval
        bufferSize
        roleId
        encrypted
        kmsKeyId
        loggingConfiguration
    ]

    [#return
        {
            "BucketARN" : getArn(bucketId),
            "BufferingHints" : {
                "IntervalInSeconds" : bufferInterval,
                "SizeInMBs" : bufferSize
            },
            "CompressionFormat" : "GZIP",
            "Prefix" : bucketPrefix?ensure_ends_with("/"),
            "RoleARN" : getReference(roleId, ARN_ATTRIBUTE_TYPE),
            "CloudWatchLoggingOptions" : loggingConfiguration
        } +
        attributeIfTrue(
            "EncryptionConfiguration",
            encrypted,
            {
                "KMSEncryptionConfig" : {
                    "AWSKMSKeyARN" : getReference(kmsKeyId, ARN_ATTRIBUTE_TYPE)
                }
            }
        )
    ]
[/#function]

[#function getFirehoseStreamS3Destination
        bucketId
        bucketPrefix
        errorPrefix
        bufferInterval
        bufferSize
        roleId
        encrypted
        kmsKeyId
        loggingConfiguration
        backupEnabled
        backupS3Destination
        lambdaProcessor
]

[#return
 {
     "ExtendedS3DestinationConfiguration" : {
        "BucketARN" : getArn(bucketId),
        "BufferingHints" : {
                "IntervalInSeconds" : bufferInterval,
                "SizeInMBs" : bufferSize
            },
        "CloudWatchLoggingOptions" : loggingConfiguration,
        "CompressionFormat" : "GZIP",
        "RoleARN" : getReference(roleId, ARN_ATTRIBUTE_TYPE),
        "S3BackupMode" : backupEnabled?then("Enabled", "Disabled")
    } +
    attributeIfContent(
        "ProcessingConfiguration",
        lambdaProcessor,
        {
            "Enabled" : true,
            "Processors" : asArray(lambdaProcessor)
        }
    ) +
    attributeIfContent(
        "Prefix",
        bucketPrefix,
        bucketPrefix?ensure_ends_with("/")
    ) +
    attributeIfContent(
        "ErrorOutputPrefix",
        errorPrefix,
        errorPrefix?ensure_ends_with("/")
    ) +
    attributeIfTrue(
        "EncryptionConfiguration",
        encrypted,
        {
            "KMSEncryptionConfig" : {
                "AWSKMSKeyARN" : getReference(kmsKeyId, ARN_ATTRIBUTE_TYPE)
            }
        }
    ) +
    attributeIfTrue(
        "S3BackupConfiguration"
        backupEnabled,
        backupS3Destination
    )
 }
]
[/#function]

[#function getFirehoseStreamLoggingConfiguration
        enabled
        logGroupName=""
        logStreamName="" ]

    [#return
        {
                "Enabled" : enabled
        } +
        enabled?then(
            {
                "LogGroupName" : logGroupName,
                "LogStreamName" : logStreamName
            },
            {}
        )
    ]
[/#function]

[#function getFirehoseStreamLambdaProcessor
    lambdaId
    roleId
    bufferInterval
    bufferSize ]

    [#return
        {
            "Type" : "Lambda",
            "Parameters" : [
                {
                    "ParameterName" : "BufferIntervalInSeconds",
                    "ParameterValue" : bufferInterval?c
                },
                {
                    "ParameterName" : "BufferSizeInMBs",
                    "ParameterValue" : bufferSize?c
                },
                {
                    "ParameterName" : "LambdaArn",
                    "ParameterValue" : getArn(lambdaId)
                },
                {
                    "ParameterName" : "RoleArn",
                    "ParameterValue" : getArn(roleId)
                }
            ]
        }
    ]

[/#function]
