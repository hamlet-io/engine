[#-- CloudFront --]

[#assign CLOUDFRONT_DISTRIBUTION_RESOURCE_TYPE = "cf" ]
[#assign CLOUDFRONT_ACCESS_ID_RESOURCE_TYPE = "cfaccess" ]
[#assign CLOUDFRONT_ORIGIN_RESOURCE_TYPE = "cforigin" ]

[#function formatDependentCFDistributionId resourceId extensions...]
    [#return formatDependentResourceId(
                CLOUDFRONT_DISTRIBUTION_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatComponentCFDistributionId tier component extensions...]
    [#return formatComponentResourceId(
                CLOUDFRONT_DISTRIBUTION_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatDependentCFAccessId resourceId extensions...]
    [#return formatDependentResourceId(
                CLOUDFRONT_ACCESS_ID_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

