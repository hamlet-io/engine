[#-- S3 --]

[#-- Resources --]

[#function formatS3Id ids...]
    [#return formatResourceId(
            "s3",
            ids)]
[/#function]

[#-- TODO: Remove when use of "container" is removed --]
[#function formatContainerS3Id type extensions...]
    [#return formatContainerResourceId(
                "s3",
                type,
                extensions)]
[/#function]

[#function formatSegmentS3Id type extensions...]
    [#return formatSegmentResourceId(
                "s3",
                type,
                extensions)]
[/#function]

[#function formatComponentS3Id tier component extensions...]
    [#return formatComponentResourceId(
                "s3",
                tier,
                component,
                extensions)]
[/#function]

[#function formatAccountS3Id type extensions...]
    [#return formatAccountResourceId(
                "s3",
                type,
                extensions)]
[/#function]

[#function formatS3BucketPolicyId s3Id]
    [#-- TODO: Should be using formatPolicyId(s3Id) --]
    [#return formatId(
                s3Id,
                "policy")]
[/#function]

[#function formatS3NotificationsQueuePolicyId s3Id queue]
    [#return formatPolicyId(
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
