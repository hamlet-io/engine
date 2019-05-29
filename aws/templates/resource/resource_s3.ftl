[#-- S3 --]

[#function getS3LifecycleExpirationRule days prefix="" enabled=true]
    [#return
        [
            {
                "Status" : enabled?then("Enabled","Disabled")
            } +
            attributeIfContent("Prefix", prefix) +
            attributeIfTrue("ExpirationInDays", days?is_number, days) +
            attributeIfTrue("ExpirationDate", !(days?is_number), days)
        ]
    ]
[/#function]

[#function getS3LifecycleRule
        expirationdays=""
        transitiondays=""
        prefix=""
        enabled=true
        noncurrentexpirationdays=""
        noncurrenttransitiondays="" ]

    [#-- Alias overrides - Expiration --]
    [#if expirationdays?is_string ]
        [#switch expirationdays ]
            [#case "_operations" ]
                [#local expirationTime = operationsExpiration]
                [#break ]
            [#case "_data" ]
                [#local expirationTime = dataExpiration ]
                [#break]
            [#default]
                [#local expirationTime = expirationdays]
        [/#switch]
    [#else]
        [#local expirationTime = expirationdays ]
    [/#if]

    [#-- Alias overrides - Transition --]
    [#if transitiondays?is_string ]
        [#switch transitiondays ]
            [#case "_operations" ]
                [#local transitionTime = operationsOffline]
                [#break ]
            [#case "_data" ]
                [#local transitionTime = dataOffline ]
                [#break]
            [#default]
                [#local transitionTime = transitiondays]
        [/#switch]
    [#else]
        [#local transitionTime = transitiondays ]
    [/#if]

    [#if expirationTime?has_content && !(noncurrentexpirationdays?has_content)]
        [#local noncurrentexpirationdays = expirationTime ]
    [/#if]

    [#if transitionTime?has_content && !(noncurrenttransitiondays?has_content)]
        [#local noncurrenttransitiondays = transitionTime ]
    [/#if]

    [#if transitionTime?has_content || expirationTime?has_content ||
            noncurrentexpirationdays?has_content || noncurrenttransitiondays?has_content ]
        [#return
            [
                {
                    "Status" : enabled?then("Enabled","Disabled")
                } +
                attributeIfContent("Prefix", prefix) +
                (expirationTime?has_content)?then(
                    attributeIfTrue("ExpirationInDays", expirationTime?is_number, expirationTime) +
                    attributeIfTrue("ExpirationDate", !(expirationTime?is_number), expirationTime),
                    {}
                ) +
                (transitionTime?has_content)?then(
                    {
                        "Transitions" : [
                            {
                                "StorageClass" : "GLACIER"
                            } +
                            attributeIfTrue("TransitionInDays", transitionTime?is_number, transitionTime) +
                            attributeIfTrue("TransitionDate", !(transitionTime?is_number), transitionTime)
                        ]
                    },
                    {}
                ) +
                attributeIfContent("NoncurrentVersionExpirationInDays", noncurrentexpirationdays) +
                (noncurrenttransitiondays?has_content)?then(
                    {
                        "NoncurrentVersionTransitions" : [
                            {
                                "StorageClass" : "GLACIER",
                                "TransitionInDays" : noncurrenttransitiondays
                            }
                        ]
                    },
                    {}
                )
            ]
        ]
    [#else]
        [#return []]
    [/#if]
[/#function]

[#function getS3LoggingConfiguration logBucket prefix ]
    [#return
        {
            "DestinationBucketName" : logBucket,
            "LogFilePrefix" : "s3/" + prefix + "/"
        }
    ]
[/#function]

[#function getS3SQSNotification queue event prefix="" suffix="" ]
    [#local filterRules = [] ]
    [#if prefix?has_content ]   
        [#local filterRules += 
            [ {
                "Name" : "prefix",
                "Value" : prefix
            }] ]
    [/#if]

    [#if suffix?has_content ]
        [#local filterRules += 
            [ 
                {
                    "Name" : "suffix",
                    "Value" : suffix
                }
            ]
        ]
    [/#if]

    [#-- Aliases for notification events --]
    [#switch event ]
        [#case "create" ]
            [#local event = "s3:ObjectCreated:*" ]
            [#break]
        [#case "delete" ]
            [#local event = "s3:ObjectRemoved:*" ]
            [#break]
        [#case "restore" ]
            [#local event ="s3:ObjectRestore:*"]
            [#break]
        [#case "reducedredundancy" ]    
            [#local event = "s3:ReducedRedundancyLostObject" ]
            [#break]
    [/#switch]

    [#return
        [
            {
                "Event" : event,
                "Queue" : getReference(queue, ARN_ATTRIBUTE_TYPE )
            } + 
            attributeIfContent(
                "Filter",
                filterRules,
                {
                    "S3Key" :{
                        "Rules" : filterRules
                    }
                }
            )
        ]
    ]
[/#function]

[#function getS3WebsiteConfiguration index error redirectTo="" redirectProtocol=""]
    [#-- If redirecting, only the redirection info can be provided --]
    [#if redirectTo?has_content]
        [#return
            {
                "RedirectAllRequestsTo" : {
                    "HostName" : redirectTo
                } +
                attributeIfContent("Protocol", redirectProtocol)
            }
        ]
    [#else]
        [#return
            {
                "IndexDocument" : index
            } +
            attributeIfContent("ErrorDocument", error)
        ]
    [/#if]
[/#function]

[#function getS3ReplicationConfiguration 
    roleId
    replicationRules
    ]
    [#return
        {
            "Role" : getReference(roleId, ARN_ATTRIBUTE_TYPE),
            "Rules" : asArray(replicationRules)
        }
    ]
[/#function]

[#function getS3ReplicationRule 
    destinationBucket
    enabled
    prefix
    encryptReplica=false
]
    [#return 
        {
            "Destination" : {
                "Bucket" : getArn(destinationBucket)
            } + 
            encryptReplica?then(
                    {
                        "EncryptionConfiguration" : {
                        "ReplicaKmsKeyID" : getReference(formatSegmentCMKId(), ARN_ATTRIBUTE_TYPE)
                        }
                    },
                    {}
            ),
            "Prefix" : prefix,    
            "Status" : enabled?then(
                "Enabled",
                "Disabled"
            )
        }
        + encryptReplica?then(
            {
                "SourceSelectionCriteria" : {
                    "SseKmsEncryptedObjects" : {
                        "Status" : "Enabled"
                    }
                }
            },
            {}
        )
    ]
[/#function]

[#assign S3_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        NAME_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "Attribute" : "Arn"
        },
        DNS_ATTRIBUTE_TYPE : {
            "Attribute" : "DomainName"
        },
        URL_ATTRIBUTE_TYPE : {
            "Attribute" : "WebsiteURL"
        },
        REGION_ATTRIBUTE_TYPE: {
            "Value" : { "Ref" : "AWS::Region" }
        }
    }
]

[#assign outputMappings +=
    {
        AWS_S3_RESOURCE_TYPE : S3_OUTPUT_MAPPINGS
    }
]

[#macro createS3Bucket mode id name tier="" component=""
                        lifecycleRules=[]
                        sqsNotifications=[]
                        versioning=false
                        websiteConfiguration={}
                        replicationConfiguration={}
                        cannedACL=""
                        CORSBehaviours=[]
                        dependencies=""
                        outputId=""]

    [#assign loggingConfiguration = {} ]
    [#if getExistingReference(formatAccountS3Id("audit"), "", regionId )?has_content ]
        [#assign loggingConfiguration = getS3LoggingConfiguration(
                                getExistingReference(formatAccountS3Id("audit")),
                                name) ]
    [/#if]

    [#local versionConfiguration={}]
    [#if versioning ]
        [#local versionConfiguration = {
            "Status" : "Enabled"
        } ]
    [/#if]

    [#assign CORSRules = [] ]
    [#list CORSBehaviours as behaviour ]
        [#assign CORSBehaviour = CORSProfiles[behaviour] ]
        [#if CORSBehaviour?has_content ]
            [#assign CORSRules += [
                {
                    "Id" : behaviour,
                    "AllowedHeaders" : CORSBehaviour.AllowedHeaders,
                    "AllowedMethods" : CORSBehaviour.AllowedMethods,
                    "AllowedOrigins" : CORSBehaviour.AllowedOrigins,
                    "ExposedHeaders" : CORSBehaviour.ExposedHeaders,
                    "MaxAge" : (CORSBehaviour.MaxAge)?c
                }
            ]]
        [/#if]
    [/#list]

    [@cfResource
        mode=mode
        id=id
        type="AWS::S3::Bucket"
        properties=
            {
                "BucketName" : name
            } +
            attributeIfContent(
                "LifecycleConfiguration",
                lifecycleRules,
                {
                    "Rules" : lifecycleRules
                }) +
            attributeIfContent(
                "NotificationConfiguration",
                sqsNotifications,
                {
                    "QueueConfigurations" : sqsNotifications
                }) +
            attributeIfContent(
                "WebsiteConfiguration",
                websiteConfiguration
            ) +
            attributeIfContent(
                "LoggingConfiguration",
                loggingConfiguration
            ) +
            attributeIfContent(
                "AccessControl",
                cannedACL
            ) +
            attributeIfContent(
                "VersioningConfiguration",
                versionConfiguration
            ) +
            attributeIfContent(
                "CorsConfiguration",
                CORSRules,
                {
                    "CorsRules" : CORSRules
                }
            ) +
            attributeIfContent(
                "ReplicationConfiguration",
                replicationConfiguration
            )
        tags=getCfTemplateCoreTags("", tier, component, "", false, false, 7)
        outputs=S3_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]


