[#ftl]

[#-- Resources --]
[#assign AWS_SNS_TOPIC_RESOURCE_TYPE = "snstopic"]
[#assign AWS_SNS_SUBSCRIPTION_RESOURCE_TYPE = "snssub"]
[#assign AWS_SNS_PLATFORMAPPLICATION_RESOURCE_TYPE = "snsplatformapp" ]

[#function formatSNSTopicId ids...]
    [#return formatResourceId(
                AWS_SNS_TOPIC_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentSNSTopicId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_SNS_TOPIC_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatSegmentSNSTopicId extensions...]
    [#return formatSegmentResourceId(
                AWS_SNS_TOPIC_RESOURCE_TYPE,
                extensions)]
[/#function]


[#function formatDependentSNSSubscriptionId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_SNS_SUBSCRIPTION_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]
