[#-- SNS --]

[#-- Resources --]

[#function formatSNSTopicId ids...]
    [#return formatResourceId(
                "snstopic",
                ids)]
[/#function]

[#function formatDependentSNSTopicId resourceId extensions...]
    [#return formatDependentResourceId(
                "snstopic",
                resourceId,
                extensions)]
[/#function]

[#function formatSegmentSNSTopicId extensions...]
    [#return formatSegmentResourceId(
                "snstopic",
                extensions)]
[/#function]

[#function formatProductSNSTopicId extensions...]
    [#return formatProductResourceId(
                "snstopic",
                extensions)]
[/#function]

[#function formatDependentSNSSubscriptionId resourceId extensions...]
    [#return formatDependentResourceId(
                "snssub",
                resourceId,
                extensions)]
[/#function]
