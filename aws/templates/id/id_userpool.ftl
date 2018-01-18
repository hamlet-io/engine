[#-- Cognito UserPool --]

[#assign USERPOOL_RESOURCE_TYPE = "userpool"]

[#function formatUserPoolId tier component extensions...]
    [#return formatComponentResourceId(
                USERPOOL_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]