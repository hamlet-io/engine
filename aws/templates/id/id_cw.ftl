[#-- CloudWatch --]

[#-- Resources --]

[#function formatLogGroupId ids...]
    [#return formatResourceId(
                "lg",
                ids)]
[/#function]

[#function formatDependentLogGroupId resourceId extensions...]
    [#return formatDependentResourceId(
                "lg",
                resourceId,
                extensions)]
[/#function]

[#function formatComponentLogGroupId tier component extensions...]
    [#return formatComponentResourceId(
                "lg",
                tier,
                component,
                extensions)]
[/#function]

