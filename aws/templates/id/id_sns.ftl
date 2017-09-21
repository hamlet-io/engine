[#-- SNS --]

[#-- Resources --]

[#assign SNS_TOPIC_RESOURCE_TYPE = "snstopic"]
[#assign SNS_SUBSCRIPTION_RESOURCE_TYPE = "snssub"]

[#function formatSNSTopicId ids...]
    [#return formatResourceId(
                SNS_TOPIC_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentSNSTopicId resourceId extensions...]
    [#return formatDependentResourceId(
                SNS_TOPIC_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatSegmentSNSTopicId extensions...]
    [#return formatSegmentResourceId(
                SNS_TOPIC_RESOURCE_TYPE,
                extensions)]
[/#function]

[#function formatProductSNSTopicId extensions...]
    [#return formatProductResourceId(
                SNS_TOPIC_RESOURCE_TYPE,
                extensions)]
[/#function]

[#function formatDependentSNSSubscriptionId resourceId extensions...]
    [#return formatDependentResourceId(
                SNS_SUBSCRIPTION_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]
