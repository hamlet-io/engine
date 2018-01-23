[#-- Cognito UserPool --]

[#assign USERPOOL_RESOURCE_TYPE = "userpool"]
[#assign USERPOOL_CLIENT_RESOURCE_TYPE = "userpoolclient" ]
[#function formatUserPoolId tier component extensions...]
    [#return formatComponentResourceId(
                USERPOOL_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatUserPoolClientId tier component extensions... ]
    [#return formatComponentResourceId(
            USERPOOL_CLIENT_RESOURCE_TYPE,
            tier,
            component,
            extensions)]
[/#function]