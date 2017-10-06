[#-- CloudFront --]

[#assign CF_RESOURCE_TYPE = "cf" ]
[#assign CF_ACCESS_ID_RESOURCE_TYPE = "cfaccess" ]

[#function formatDependentCFDistributionId resourceId extensions...]
    [#return formatDependentResourceId(
                CF_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatComponentCFDistributionId tier component extensions...]
    [#return formatComponentResourceId(
                CF_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatDependentCFAccessId resourceId extensions...]
    [#return formatDependentResourceId(
                CF_ACCESS_ID_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

