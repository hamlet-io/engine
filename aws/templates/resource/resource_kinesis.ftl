[#-- kineses --]

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

[#assign outputMappings +=
    {
        AWS_KINESIS_FIREHOSE_STREAM_RESOURCE_TYPE : KINESIS_FIREHOSE_STREAM_OUTPUT_MAPPINGS
    }
]

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


[#macro createFirehoseStream mode id name destination ]
    [@cfResource
        mode=mode
        id=id
        type="AWS::KinesisFirehose::DeliveryStream"
        properties=
            {
                "DeliveryStreamName" : name
            } +
            destination
        outputs=KINESIS_FIREHOSE_STREAM_OUTPUT_MAPPINGS
    /]
[/#macro]

[#function getFirehoseStreamESDestination 
        bufferInterval 
        bufferSize 
        esDomainId 
        roleId
        indexName
        indexRotation
        documentType
        retryDuration
        backupPolicy
        backupS3Destination
        loggingConfiguration ]
    
    [#local roleArn = getReference(roleId, ARN_ATTRIBUTE_TYPE)]
    [#local backupLogStreamName = "S3Backup" ]

    [#return 
        {
            "ElasticsearchDestinationConfiguration" : {
                "BufferingHints" : {
                    "IntervalInSeconds" : bufferInterval,
                    "SizeInMBs" : bufferSize
                },
                "DomainARN" : getReference(esDomainId, ARN_ATTRIBUTE_TYPE),
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
            } 
        }
    ]
[/#function]

[#function getFirehoseStreamS3Destination 
        bucketId
        bucketPrefix
        bufferInterval
        bufferSize
        roleId
        encrypted
        loggingConfiguration
    ]

    [#return 
        {
            "BucketARN" : getReference(bucketId, ARN_ATTRIBUTE_TYPE),
            "BufferingHints" : {
                "IntervalInSeconds" : bufferInterval,
                "SizeInMBs" : bufferSize
            },
            "CompressionFormat" : "GZIP",
            "Prefix" : bucketPrefix,
            "RoleARN" : getReference(roleId, ARN_ATTRIBUTE_TYPE),
            "CloudWatchLoggingOptions" : loggingConfiguration
        } + 
        attributeIfTrue(
            "EncryptionConfiguration",
            encrypted,
            {
                "KMSEncryptionConfig" : {
                    "AWSKMSKeyARN" : getReference(formatSegmentCMKId(), ARN_ATTRIBUTE_TYPE)
                }
            }
        )
    
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