[#-- Cognito UserPool --]

[#assign USERPOOL_RESOURCE_TYPE = "userpool"]

[#function formatUserPoolId ids...]
    [#return formatResourceId(
                USERPOOL_RESOURCE_TYPE,
                ids)]
[/#function]
