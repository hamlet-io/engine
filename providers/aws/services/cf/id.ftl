[#ftl]

[#-- Resources --]
[#assign AWS_CLOUDFRONT_DISTRIBUTION_RESOURCE_TYPE = "cf" ]
[#assign AWS_CLOUDFRONT_ACCESS_ID_RESOURCE_TYPE = "cfaccess" ]
[#assign AWS_CLOUDFRONT_ORIGIN_RESOURCE_TYPE = "cforigin" ]

[#function formatDependentCFDistributionId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_CLOUDFRONT_DISTRIBUTION_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatComponentCFDistributionId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_CLOUDFRONT_DISTRIBUTION_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatDependentCFAccessId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_CLOUDFRONT_ACCESS_ID_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

