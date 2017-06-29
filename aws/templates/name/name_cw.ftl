[#-- CloudWatch --]

[#-- Resources --]

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
