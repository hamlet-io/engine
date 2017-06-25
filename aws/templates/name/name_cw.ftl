[#-- CloudWatch --]

[#-- Resources --]

[#function formatComponentLogGroupName tier component extensions...]
    [#return formatComponentAbsoluteFullPath(
                tier,
                component,
                extensions)]
[/#function]
