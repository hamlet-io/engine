[#-- S3 --]

[#-- Resources --]
[#assign AWS_S3_RESOURCE_TYPE = "s3" ]
[#assign AWS_S3_BUCKET_POLICY_RESOURCE_TYPE="bucketpolicy" ]

[#function formatS3Id ids...]
    [#return formatResourceId(
            AWS_S3_RESOURCE_TYPE,
            ids)]
[/#function]

[#-- TODO: Remove when use of "container" is removed --]
[#function formatContainerS3Id type extensions...]
    [#return formatContainerResourceId(
                AWS_S3_RESOURCE_TYPE,
                type,
                extensions)]
[/#function]

[#function formatSegmentS3Id type extensions...]
    [#return formatSegmentResourceId(
                AWS_S3_RESOURCE_TYPE,
                type,
                extensions)]
[/#function]

[#function formatOccurrenceS3Id occurrence extensions...]
    [#return formatComponentResourceId(
                AWS_S3_RESOURCE_TYPE,
                occurrence.Core.Tier,
                occurrence.Core.Component,
                occurrence,
                extensions)]
[/#function]

[#function formatProductS3Id type extensions...]
    [#return formatProductResourceId(
                AWS_S3_RESOURCE_TYPE,
                type,
                extensions)]
[/#function]

[#function formatAccountS3Id type extensions...]
    [#return formatAccountResourceId(
                AWS_S3_RESOURCE_TYPE,
                type,
                extensions)]
[/#function]

[#function formatBucketPolicyId ids...]
    [#return formatResourceId(
                AWS_S3_BUCKET_POLICY_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentBucketPolicyId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_S3_BUCKET_POLICY_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatS3NotificationsQueuePolicyId s3Id queue]
    [#return formatDependentPolicyId(
                s3Id,
                queue)]
[/#function]


[#-- Component --]
[#assign S3_COMPONENT_TYPE = "s3" ]

[#assign componentConfiguration +=
    {
        S3_COMPONENT_TYPE : [
            {
                "Name" : "Lifecycle",
                "Children" : [
                    {
                        "Name" : "Expiration"
                    }
                ]
            },
            { 
                "Name" : "Website",
                "Children" : [
                    {
                        "Name"  : "Enabled",
                        "Default" : true
                    },
                    {
                        "Name": "Index",
                        "Default": "index.html"
                    },
                    {
                        "Name": "Error",
                        "Default": ""
                    }
                ]
            }
            "Style",
            "Notifications"
        ]
    }]
    
[#function getS3State occurrence]
    [#local core = occurrence.Core]

    [#local id = formatOccurrenceS3Id(occurrence)]
    [#local name = formatOccurrenceBucketName(occurrence) ]

    [#return
        {
            "Resources" : {
                "bucket" : {
                    "Id" : id,
                    "Name" :
                        firstContent(
                            getExistingReference(id, NAME_ATTRIBUTE_TYPE),
                            name),
                    "Type" : AWS_S3_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "NAME" : getExistingReference(id, NAME_ATTRIBUTE_TYPE),
                "FQDN" : getExistingReference(id, DNS_ATTRIBUTE_TYPE),
                "INTERNAL_FQDN" : getExistingReference(id, DNS_ATTRIBUTE_TYPE),
                "WEBSITE_URL" : getExistingReference(id, URL_ATTRIBUTE_TYPE),
                "ARN" : getExistingReference(id, ARN_ATTRIBUTE_TYPE),
                "REGION" : regionId
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]
