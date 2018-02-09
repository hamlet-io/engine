[#-- Cognito UserPool --]

[#assign USERPOOL_RESOURCE_TYPE = "userpool"]
[#assign USERPOOL_CLIENT_RESOURCE_TYPE = "userpoolclient" ]
[#assign IDENTITYPOOL_RESOURCE_TYPE = "identitypool" ]

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

[#function formatIdentityPoolId tier component extensions... ]
    [#return formatComponentResourceId(
            IDENTITYPOOL_RESOURCE_TYPE,
            tier,
            component,
            extensions)]
[/#function]

[#function formatDependentIdentityPoolRoleMappingId resourceId extensions...]
    [#return formatDependentResourceId(
            "rolemapping",
            resourceId,
            extensions)]
[/#function]

[#function formatDependentIdentityPoolUnAuthRoleId resourceId extensions... ]
    [#return 
        formatDependentRoleId(
            resourceId,
            "unauth",
            extensions)]
    ]
[/#function]

[#function formatDependentIdentityPoolAuthRoleId resourceId extensions... ]
    [#return 
        formatDependentRoleId(
                resourceId,
                "auth",
                extensions)]
    ]
[/#function]
