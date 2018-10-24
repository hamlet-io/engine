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

    [#if transitiondays?has_content && !(noncurrenttransitiondays?has_content)]
        [#local noncurrenttransitiondays = transitiondays ]
    [/#if]

    [#if expirationdays?has_content && !(noncurrentexpirationdays?has_content)]
        [#local noncurrentexpirationdays = expirationdays ]
    [/#if]

    [#return
        [
            {
                "Status" : enabled?then("Enabled","Disabled")
            } +
            attributeIfContent("Prefix", prefix) +
            (expirationdays?has_content)?then(
                attributeIfTrue("ExpirationInDays", expirationdays?is_number, expirationdays) +
                attributeIfTrue("ExpirationDate", !(expirationdays?is_number), expirationdays),
                {}
            ) +
            (transitiondays?has_content)?then(
                {
                    "Transitions" : [
                        {
                            "StorageClass" : "GLACIER"
                        } +
                        attributeIfTrue("TransitionInDays", transitiondays?is_number, transitiondays) +
                        attributeIfTrue("TransitionDate", !(transitiondays?is_number), transitiondays)
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
[/#function]

[#function getS3LoggingConfiguration logBucket prefix ]
    [#return
        {
            "DestinationBucketName" : logBucket,
            "LogFilePrefix" : "s3/" + prefix + "/"
        }
    ]
[/#function]

[#function getS3SQSNotification queue event]
    [#return
        [
            {
                "Event" : event,
                "Queue" : getReference(queue, ARN_ATTRIBUTE)
            }
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
                        cannedACL=""
                        CORSBehaviours=[]
                        dependencies=""
                        outputId=""]

    [#assign loggingConfiguration = {} ]
    [#if getExistingReference(formatAccountS3Id("audit"))?has_content ]
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
            )
        tags=getCfTemplateCoreTags("", tier, component)
        outputs=S3_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]


