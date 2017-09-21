[#-- CloudFront --]

[#-- Resources --]

[#assign CF_RESOURCE_TYPE = "cf" ]

[#function formatDependentCFDistributionId resourceId extensions...]
    [#return formatDependentResourceId(
                CF_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]
