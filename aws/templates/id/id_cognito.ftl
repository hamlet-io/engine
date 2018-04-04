[#-- Cognito UserPool --]

[#-- Resources --]
[#assign AWS_COGNITO_USERPOOL_RESOURCE_TYPE = "userpool"]
[#assign AWS_COGNITO_USERPOOL_CLIENT_RESOURCE_TYPE = "userpoolclient"]
[#assign AWS_COGNITO_IDENTITYPOOL_RESOURCE_TYPE = "identitypool"]
[#assign AWS_COGNITO_IDENTITYPOOL_ROLEMAPPING_RESOURCE_TYPE = "rolemapping"]


[#-- Components --]
[#assign USERPOOL_COMPONENT_TYPE = "userpool"]
[#assign USERPOOL_COMPONENT_ROLE_UNAUTH_EXTENSTION = "unauth" ]
[#assign USERPOOL_COMPONENT_ROLE_AUTH_EXTENSTION = "auth" ]

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
                "Name" : "UnusedAccountTimeout",
                "Default" : 7
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
            },
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

    [#assign userPoolId = formatResourceId(AWS_COGNITO_USERPOOL_RESOURCE_TYPE, core.Id)]
    [#assign userPoolName = formatSegmentFullName(core.Name)]

    [#assign userPoolClientId = formatResourceId(AWS_COGNITO_USERPOOL_CLIENT_RESOURCE_TYPE, core.Id)]
    [#assign userPoolClientName = formatSegmentFullName(core.Name)]

    [#assign identityPoolId = formatResourceId(AWS_COGNITO_IDENTITYPOOL_RESOURCE_TYPE, core.Id)]
    [#assign identityPoolName = formatSegmentFullName(core.Name)?replace("-","X")]

    [#assign identityPoolRoleMappingId = formatDependentResourceId(AWS_COGNITO_IDENTITYPOOL_ROLEMAPPING_RESOURCE_TYPE, identityPoolId)]

    [#assign userPoolRoleId = formatComponentRoleId(core.Tier, core.Component)]

    [#assign identityPoolUnAuthRoleId = formatDependentRoleId(identityPoolId,USERPOOL_COMPONENT_ROLE_UNAUTH_EXTENSTION )]
    [#assign identityPoolAuthRoleId = formatDependentRoleId(identityPoolId,USERPOOL_COMPONENT_ROLE_AUTH_EXTENSTION )]
        
    [#return
        {
            "Resources" : {
                "userpool" : {
                    "Id" : userPoolId,
                    "Name" : userPoolName,
                    "Type" : AWS_COGNITO_USERPOOL_RESOURCE_TYPE
                },
                "client" : {
                    "Id" : userPoolClientId,
                    "Name" : userPoolClientName,
                    "Type" : AWS_COGNITO_USERPOOL_CLIENT_RESOURCE_TYPE
                },
                "identitypool" : { 
                    "Id" : identityPoolId,
                    "Name" : identityPoolName,
                    "Type" : AWS_COGNITO_IDENTITYPOOL_RESOURCE_TYPE
                },
                "userpoolrole" : {
                    "Id" : userPoolRoleId,
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                },
                "unauthrole" : { 
                    "Id" : identityPoolUnAuthRoleId,
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                },
                "authrole" : {
                    "Id" : identityPoolAuthRoleId,
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                },
                "rolemapping" : {
                    "Id" : identityPoolRoleMappingId,
                    "Type" : AWS_COGNITO_IDENTITYPOOL_ROLEMAPPING_RESOURCE_TYPE
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

