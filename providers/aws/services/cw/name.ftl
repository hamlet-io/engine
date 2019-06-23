[#ftl]

[#function formatSegmentLogGroupName extensions...]
    [#return formatSegmentAbsolutePath(
                extensions)]
[/#function]

[#function formatComponentLogGroupName tier component extensions...]
    [#return formatComponentAbsoluteFullPath(
                tier,
                component,
                extensions)]
[/#function]

[#function formatComponentAlarmName tier component extensions...]
    [#return formatComponentFullName(
                tier,
                component,
                extensions)]
[/#function]
