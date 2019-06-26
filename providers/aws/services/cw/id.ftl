[#ftl]

[#-- Resources --]
[#assign AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE = "lg" ]
[#assign AWS_CLOUDWATCH_LOG_GROUP_STREAM_RESOURCE_TYPE = "lgstream" ]
[#assign AWS_CLOUDWATCH_DASHBOARD_RESOURCE_TYPE = "dashboard" ]
[#assign AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE = "lmetric" ]
[#assign AWS_CLOUDWATCH_LOG_SUBSCRIPTION_RESOURCE_TYPE = "lsubscription" ]
[#assign AWS_CLOUDWATCH_ALARM_RESOURCE_TYPE = "alarm" ]

[#assign AWS_EVENT_RULE_RESOURCE_TYPE = "event" ]

[#function formatLogGroupId ids...]
    [#return formatResourceId(
                AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentLogGroupId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatComponentLogGroupId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatAccountLogGroupId ids...]
    [#return formatAccountResourceId(
                AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentLogMetricId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatDependentLogSubscriptionId resourceId extensions... ]
    [#return formatDependentResourceId(
                AWS_CLOUDWATCH_LOG_SUBSCRIPTION_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatSegmentCWDashboardId extensions...]
    [#return formatSegmentResourceId(
                AWS_CLOUDWATCH_DASHBOARD_RESOURCE_TYPE,
                extensions)]
[/#function]

[#function formatAlarmId ids...]
    [#return formatResourceId(
                AWS_CLOUDWATCH_ALARM_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentAlarmId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_CLOUDWATCH_ALARM_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatEventRuleId occurrence extensions...]
    [#return formatResourceId(
                AWS_EVENT_RULE_RESOURCE_TYPE,
                occurrence.Core.Id,
                extensions)]
[/#function]
