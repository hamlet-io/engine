[#-- CloudWatch --]

[#-- Resources --]

[#assign LOG_GROUP_RESOURCE_TYPE = "lg" ]

[#function formatLogGroupId ids...]
    [#return formatResourceId(
                LOG_GROUP_RESOURCE_TYPE,
                ids)]
[/#function]

[#function formatDependentLogGroupId resourceId extensions...]
    [#return formatDependentResourceId(
                LOG_GROUP_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatComponentLogGroupId tier component extensions...]
    [#return formatComponentResourceId(
                LOG_GROUP_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatLogMetricId ids...]
    [#return formatResourceId(
                "lmetric",
                ids)]
[/#function]

[#function formatDependentLogMetricId resourceId extensions...]
    [#return formatDependentResourceId(
                "lmetric",
                resourceId,
                extensions)]
[/#function]

[#function formatSegmentCWDashboardId extensions...]
    [#return formatSegmentResourceId(
                "cwdashboard",
                extensions)]
[/#function]

[#function formatAlarmId ids...]
    [#return formatResourceId(
                "alarm",
                ids)]
[/#function]

[#function formatDependentAlarmId resourceId extensions...]
    [#return formatDependentResourceId(
                "alarm",
                resourceId,
                extensions)]
[/#function]

