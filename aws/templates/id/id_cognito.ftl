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

[#assign componentConfiguration +=
    {
        "userpool" : [
            { 
                "Name" : "MFA",
                "Default" : false
            },
            {
                "Name" : "adminCreatesUser",
                "Default" : true
            },
            {
                "Name" : "unusedAccountTimeout"
            },
            {
                "Name" : "verifyEmail",
                "Default" : true
            },
            {
                "Name" : "verifyPhone",
                "Default" : false
            },
            {
                "Name" : "loginAliases",
                "Default" : [
                    "email"
                ]
            },
            {
                "Name" : "clientGenerateSecret",
                "Default" : false
            },
            {
                "Name" : "clientTokenValidity",
                "Default" : 30
            },
            {
                "Name" : "allowUnauthIds",
                "Default" : false
            }
            {
                "Name" : "passwordPolicy",
                "Children" : [
                    {
                       "Name" : "MinimumLength",
                       "Default" : "8"
                    },
                    {
                        "Name" : "Lowercase",
                        "Default" : true
                    },
                    {
                        "Name" : "Uppercase",
                        "Default" : true
                    },
                    {
                        "Name" : "Numbers",
                        "Default" : true
                    },
                    {
                        "Name" : "SpecialCharacters",
                        "Default" : false
                    }
                ] 
            }
        ]
    }]
    
[#function getUserPoolState occurrence]
    [#local core = occurrence.Core]

    [#local id = formatUserPoolId(core.Tier, core.Component) ]
    [#local clientId = formatUserPoolClientId(core.Tier, core.Component) ]
    [#local identityPoolId = formatIdentityPoolId(core.Tier, core.Component) ]
    [#return
        {
            "Resources" : {
                "pool" : {
                    "Id" : id
                }
            },
            "Attributes" : {
                "USER_POOL" : getReference(id),
                "IDENTITY_POOL" : getReference(identityPoolId),
                "CLIENT" : getReference(clientId),
                "REGION" : regionId
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]

