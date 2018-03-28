[#-- CloudWatch --]

[#assign CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE = "lg" ]
[#assign CLOUDWATCH_DASHBOARD_RESOURCE_TYPE = "dashboard" ]
[#assign CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE = "lmetric" ]
[#assign CLOUDWATCH_ALARM_RESOURCE_TYPE = "alarm" ]

[#function formatLogGroupId ids...]
    [#return formatResourceId(
                CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentLogGroupId resourceId extensions...]
    [#return formatDependentResourceId(
                CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatComponentLogGroupId tier component extensions...]
    [#return formatComponentResourceId(
                CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatLogMetricId ids...]
    [#return formatResourceId(
                CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentLogMetricId resourceId extensions...]
    [#return formatDependentResourceId(
                CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatSegmentCWDashboardId extensions...]
    [#return formatSegmentResourceId(
                CLOUDWATCH_DASHBOARD_RESOURCE_TYPE,
                extensions)]
[/#function]

[#function formatAlarmId ids...]
    [#return formatResourceId(
                CLOUDWATCH_ALARM_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentAlarmId resourceId extensions...]
    [#return formatDependentResourceId(
                CLOUDWATCH_ALARM_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

