[#-- Cognito User Pool --]

[#function formatUserPoolName tier component userpool ]
    [#return formatName(
                "userpoool",
                formatComponentFullName(
                    tier,
                    component,
                    lambda))]
[/#function]