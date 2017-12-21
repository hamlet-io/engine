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

[#function getS3WebsiteConfiguration index error]
    [#return 
        [
            {
                "WebsiteConfiguration" : {
                    "IndexDocument" : index,
                    "ErrorDocument" : error
                }
            }
        ]
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
        }
    }
]

[#assign outputMappings +=
    {
        S3_RESOURCE_TYPE : S3_OUTPUT_MAPPINGS
    }
]

[#macro createS3Bucket mode id name tier="" component="" lifecycleRules=[] sqsNotifications=[] websiteConfiguration={} dependencies="" outputId=""]
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
                "websiteConfiguration",
                websiteConfiguration,
                {
                    "websiteConfiguration" : websiteConfiguration
                }
            )
        tags=getCfTemplateCoreTags("", tier, component)
        outputs=S3_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]


