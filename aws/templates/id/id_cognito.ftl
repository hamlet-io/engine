[#-- Cognito UserPool --]

[#assign USERPOOL_RESOURCE_TYPE = "userpool"]
[#assign USERPOOL_CLIENT_RESOURCE_TYPE = "userpoolclient"]
[#assign IDENTITYPOOL_RESOURCE_TYPE = "identitypool"]

[#assign USERPOOL_COMPONENT_TYPE = "userpool"]

[#function formatUserPoolId occurrence extensions...]
    [#return formatComponentResourceId(
            USERPOOL_RESOURCE_TYPE,
            occurrence.Core.Tier,
            occurrence.Core.Component,
            occurrence
            extensions)]
[/#function]

[#function formatUserPoolClientId occurrence extensions...]
    [#return formatComponentResourceId(
            USERPOOL_CLIENT_RESOURCE_TYPE,
            occurrence.Core.Tier,
            occurrence.Core.Component,
            occurrence
            extensions)]
[/#function]

[#function formatIdentityPoolId occurrence extensions...]
    [#return formatComponentResourceId(
            IDENTITYPOOL_RESOURCE_TYPE,
            occurrence.Core.Tier,
            occurrence.Core.Component,
            occurrence
            extensions)]
[/#function]

[#function formatDependentIdentityPoolRoleMappingId resourceId extensions...]
    [#return formatDependentResourceId(
            "rolemapping",
            resourceId,
            extensions)]
[/#function]

[#function formatDependentIdentityPoolUnAuthRoleId resourceId extensions...]
    [#return 
        formatDependentRoleId(
            resourceId,
            "unauth",
            extensions)]
    ]
[/#function]

[#function formatDependentIdentityPoolAuthRoleId resourceId extensions...]
    [#return 
        formatDependentRoleId(
                resourceId,
                "auth",
                extensions)]
    ]
[/#function]

[#assign componentConfiguration +=
    {
        USERPOOL_COMPONENT_TYPE : [
            { 
                "Name" : "MFA",
                "Default" : false
            },
            {
                "Name" : "AdminCreatesUser",
                "Default" : true
            },
            {
                "Name" : "UnusedAccountTimeout"
            },
            {
                "Name" : "VerifyEmail",
                "Default" : true
            },
            {
                "Name" : "VerifyPhone",
                "Default" : false
            },
            {
                "Name" : "LoginAliases",
                "Default" : [
                    "email"
                ]
            },
            {
                "Name" : "ClientGenerateSecret",
                "Default" : false
            },
            {
                "Name" : "ClientTokenValidity",
                "Default" : 30
            },
            {
                "Name" : "AllowUnauthenticatedIds",
                "Default" : false
            }
            {
                "Name" : "PasswordPolicy",
                "Children" : [
                    {
                       "Name" : "MinimumLength",
                       "Default" : "10"
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
                        "Default" : true
                    }
                ] 
            },
            {
                "Name" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
    }]
    
[#function getUserPoolState occurrence]
    [#local core = occurrence.Core]

    [#assign userPoolId = formatUserPoolId(occurrence)]
    [#assign userPoolClientId = formatUserPoolClientId(occurrence)]
    [#assign userPoolRoleId = formatComponentRoleId(core.Tier, core.Component)]
    [#assign identityPoolId = formatIdentityPoolId(occurrence)]
    [#assign identityPoolUnAuthRoleId = formatDependentIdentityPoolUnAuthRoleId(identityPoolId)]
    [#assign identityPoolAuthRoleId = formatDependentIdentityPoolAuthRoleId(identityPoolId)]
    [#assign identityPoolRoleMappingId = formatDependentIdentityPoolRoleMappingId(identityPoolId)]
    [#assign userPoolName = formatUserPoolName(occurrence)]
    [#assign identityPoolName = formatIdentityPoolName(occurrence)]
    [#assign userPoolClientName = formatUserPoolClientName(occurrence)]
    
    [#return
        {
            "Resources" : {
                "userpool" : {
                    "Id" : userPoolId,
                    "Name" : userPoolName
                },
                "client" : {
                    "Id" : userPoolClientId,
                    "Name" : userPoolClientName
                },
                "identitypool" : { 
                    "Id" : identityPoolId,
                    "Name" : identityPoolName
                },
                "userpoolrole" : {
                    "Id" : userPoolRoleId
                },
                "unauthrole" : { 
                    "Id" : identityPoolUnAuthRoleId
                },
                "authrole" : {
                    "Id" : identityPoolAuthRoleId
                },
                "rolemapping" : {
                    "Id" : identityPoolRoleMappingId
                }
            },
            "Attributes" : {
                "USER_POOL" : getReference(userPoolId),
                "IDENTITY_POOL" : getReference(identityPoolId),
                "CLIENT" : getReference(userPoolClientId),
                "REGION" : regionId
            },
            "Roles" : {
                "Inbound" : {
                    "invoke" : {
                        "Principal" : "cognito-idp.amazonaws.com",
                        "SourceArn" : getReference(userPoolId,ARN_ATTRIBUTE_TYPE)
                    }
                },
                "Outbound" : {}
            }
        }
    ]
[/#function]

