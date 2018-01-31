[#-- Cognito UserPool --]

[#assign USERPOOL_RESOURCE_TYPE = "userpool"]
[#assign USERPOOL_CLIENT_RESOURCE_TYPE = "userpoolclient" ]
[#assign USERPOOL_IDENTITYPOOL_RESOURCE_TYPE = "userpoolidentitypool" ]

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

[#function formatUserPoolIdentityPoolId tier component extensions... ]
    [#return formatComponentResourceId(
            USERPOOL_IDENTITYPOOL_RESOURCE_TYPE,
            tier,
            component,
            extensions)]
[/#function]

[#function formatDependentUserPoolIdentityRoleMappingId resourceId extensions...]
    [#return formatDependentResourceId(
                "userPoolIdentityPoolRoleMapping",
                resourceId,
                extensions)]
[/#function]

[#function formatDependentUserPoolIdentityUnAuthRoleId tier component ]
    [#return 
        formatComponentRoleId(
            tier, 
            component, 
            "IdentityUnAuthRole")
    ]
[/#function]

[#function formatDependentUserPoolIdentityAuthRoleId tier component ]
    [#return 
        formatComponentRoleId(
            tier, 
            component, 
            "IdentityAuthRole")
    ]
[/#function]
