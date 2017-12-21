[#-- S3 --]

[#function getS3LifecycleExpirationRule days prefix="" enabled=true]
    [#return
        [
            {
                "Status" : enabled?then("Enabled","Disabled")
            } +
            prefix?has_content?then(
                {"Prefix" : prefix},
                {}
            ) +
            days?is_number?then(
                {"ExpirationInDays" : days},
                {"ExpirationDate" : days}
            )
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

[#function getWebsiteConfiguration index error]
    [#return
        "WebsiteConfiguration" : {
         "IndexDocument" : index,
         "ErrorDocument" : error
      }
    ]

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

[#macro createS3Bucket mode id name tier="" component="" lifecycleRules=[] sqsNotifications=[] websiteConfiguration=[] dependencies="" outputId=""]
    [@cfTemplate 
        mode=mode
        id=id
        type="AWS::S3::Bucket"
        properties=
            {
                "BucketName" : name
            } +
            lifecycleRules?has_content?then(
                {
                    "LifecycleConfiguration" : {
                        "Rules" : lifecycleRules
                    }
                },
                {}
            ) +
            sqsNotifications?has_content?then(
                {
                    "NotificationConfiguration" : {
                        "QueueConfigurations" : sqsNotifications
                    }
                },
                {}
            ) + 
            websiteConfiguration?has_content?then(
                websiteConfiguration 
            )
        tags=getCfTemplateCoreTags("", tier, component)
        outputs=S3_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]


