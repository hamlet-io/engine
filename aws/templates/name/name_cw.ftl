[#-- CloudWatch --]

[#-- Resources --]

[#function formatComponentLogGroupName tier component extensions...]
    [#return formatComponentFullPath(
                tier,
                component,
                extensions)]
[/#function]
