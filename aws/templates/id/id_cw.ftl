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

