[#-- S3 --]

[#-- Resources --]

[#assign S3_RESOURCE_TYPE = "s3" ]
[#assign BUCKET_POLICY_RESOURCE_TYPE="bucketpolicy" ]

[#function formatS3Id ids...]
    [#return formatResourceId(
            S3_RESOURCE_TYPE,
            ids)]
[/#function]

[#-- TODO: Remove when use of "container" is removed --]
[#function formatContainerS3Id type extensions...]
    [#return formatContainerResourceId(
                S3_RESOURCE_TYPE,
                type,
                extensions)]
[/#function]

[#function formatSegmentS3Id type extensions...]
    [#return formatSegmentResourceId(
                S3_RESOURCE_TYPE,
                type,
                extensions)]
[/#function]

[#function formatComponentS3Id tier component extensions...]
    [#return formatComponentResourceId(
                S3_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatAccountS3Id type extensions...]
    [#return formatAccountResourceId(
                S3_RESOURCE_TYPE,
                type,
                extensions)]
[/#function]

[#function formatBucketPolicyId ids...]
    [#return formatResourceId(
                BUCKET_POLICY_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentBucketPolicyId resourceId extensions...]
    [#return formatDependentResourceId(
                BUCKET_POLICY_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatS3NotificationsQueuePolicyId s3Id queue]
    [#return formatDependentPolicyId(
                s3Id,
                queue)]
[/#function]

[#-- Attributes --]

[#function formatS3UrlId ids...]
    [#return formatUrlAttributeId(
                formatS3Id(ids))]
[/#function]

[#-- TODO: Remove when use of "container" is removed --]
[#function formatContainerS3UrlId type extensions...]
    [#return formatUrlAttributeId(
                formatContainerS3Id(
                    type,
                    extensions))]
[/#function]

[#function formatSegmentS3UrlId type extensions...]
    [#return formatUrlAttributeId(
                formatSegmentS3Id(
                    type,
                    extensions))]
[/#function]

[#function formatComponentS3UrlId tier component extensions...]
    [#return formatUrlAttributeId(
                formatComponentS3Id(
                    tier,
                    component,
                    extensions))]
[/#function]

[#function formatAccountS3UrlId type extensions...]
    [#return formatUrlAttributeId(
                formatAccountS3Id(
                    type,
                    extensions))]
[/#function]
