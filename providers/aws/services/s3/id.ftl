[#ftl]

[#assign AWS_S3_RESOURCE_TYPE = "s3" ]
[#assign AWS_S3_BUCKET_POLICY_RESOURCE_TYPE="bucketpolicy" ]

[#function formatS3Id ids...]
    [#return formatResourceId(
            AWS_S3_RESOURCE_TYPE,
            ids)]
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

[#function formatS3NotificationPolicyId bucketId destinationId]
    [#return formatDependentPolicyId(
                bucketId,
                destinationId)]
[/#function]

