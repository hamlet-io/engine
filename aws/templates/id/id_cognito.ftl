[#-- Cognito UserPool --]

[#-- Resources --]
[#assign AWS_COGNITO_USERPOOL_RESOURCE_TYPE = "userpool"]
[#assign AWS_COGNITO_USERPOOL_CLIENT_RESOURCE_TYPE = "userpoolclient"]
[#assign AWS_COGNITO_IDENTITYPOOL_RESOURCE_TYPE = "identitypool"]
[#assign AWS_COGNITO_IDENTITYPOOL_ROLEMAPPING_RESOURCE_TYPE = "rolemapping"]
[#assign AWS_COGNITO_USERPOOL_DOMAIN_RESOURCE_TYPE = "userpooldomain" ]

[#-- Components --]
[#assign USERPOOL_COMPONENT_TYPE = "userpool"]
[#assign USERPOOL_COMPONENT_ROLE_UNAUTH_EXTENSTION = "unauth" ]
[#assign USERPOOL_COMPONENT_ROLE_AUTH_EXTENSTION = "auth" ]

[#assign componentConfiguration +=
    {
        USERPOOL_COMPONENT_TYPE : [
            { 
                "Name" : "MFA",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Name" : "AdminCreatesUser",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Name" : "UnusedAccountTimeout",
                "Type" : NUMBER_TYPE,
                "Default" : 7
            },
            {
                "Name" : "VerifyEmail",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Name" : "VerifyPhone",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Name" : "LoginAliases",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : ["email"]
            },
            {
                "Name" : "ClientGenerateSecret",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Name" : "ClientTokenValidity",
                "Type" : NUMBER_TYPE,
                "Default" : 30
            },
            {
                "Name" : "AllowUnauthenticatedIds",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Name" : "AuthorizationHeader",
                "Type" : STRING_TYPE,
                "Default" : "Authorization"
            },
            {
                "Name" : "OAuth",
                "Children" : [
                    {
                        "Name" : "Scopes",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Default" : [ "openid" ]
                    },
                    {
                        "Name" : "Flows",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Default" : [ "code" ]
                    }
                ]
            },
            {
                "Name" : "PasswordPolicy",
                "Children" : [
                    {
                        "Name" : "MinimumLength",
                        "Type" : NUMBER_TYPE,
                        "Default" : 10
                    },
                    {
                        "Name" : "Lowercase",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Name" : "Uppercase",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Name" : "Numbers",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Name" : "SpecialCharacters",
                        "Type" : BOOLEAN_TYPE,
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

    [#assign userPoolDomainId = formatResourceId(AWS_COGNITO_USERPOOL_DOMAIN_RESOURCE_TYPE, core.Id)]
    [#assign userPoolDomainName = formatName("auth", core.ShortFullName, vpc?remove_beginning("vpc-"))]

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
                "domain" : {
                    "Id" : userPoolDomainId,
                    "Name" : userPoolDomainName,
                    "Type" : AWS_COGNITO_USERPOOL_DOMAIN_RESOURCE_TYPE
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
                "AUTHORIZATION_HEADER" : occurrence.Configuration.Solution.AuthorizationHeader,
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

