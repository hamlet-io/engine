[#ftl]

[#assign USERPOOL_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        NAME_ATTRIBUTE_TYPE : {
            "Attribute" : "ProviderName"
        },
        ARN_ATTRIBUTE_TYPE : {
            "Attribute" : "Arn"
        },
        URL_ATTRIBUTE_TYPE : {
            "Attribute" : "ProviderURL"
        },
        REGION_ATTRIBUTE_TYPE: {
            "Value" : { "Ref" : "AWS::Region" }
        }
    }
]

[#assign USERPOOL_CLIENT_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UserRef" : true
        }
    }
]

[#assign IDENTITYPOOL_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        NAME_ATTRIBUTE_TYPE : {
            "Attribute" : "Name"
        }
    }
]

[#assign cogniitoMappings =
    {
        AWS_COGNITO_USERPOOL_RESOURCE_TYPE : USERPOOL_OUTPUT_MAPPINGS,
        AWS_COGNITO_USERPOOL_CLIENT_RESOURCE_TYPE : USERPOOL_CLIENT_OUTPUT_MAPPINGS,
        AWS_COGNITO_IDENTITYPOOL_RESOURCE_TYPE : IDENTITYPOOL_OUTPUT_MAPPINGS
    }
]

[#list cogniitoMappings as type, mappings]
    [@addOutputMapping 
        provider=AWS_PROVIDER
        resourceType=type
        mappings=mappings
    /]
[/#list]

[#function getUserPoolPasswordPolicy length="8" lowercase=true uppercase=true numbers=true symbols=true tempPasswordValidity=30 ]
    [#return
        {
            "PasswordPolicy" : {
                "MinimumLength"     : length,
                "RequireLowercase"  : lowercase,
                "RequireUppercase"  : uppercase,
                "RequireNumbers"    : numbers,
                "RequireSymbols"    : symbols,
                "TemporaryPasswordValidityDays" : tempPasswordValidity
            }
        }
    ]
[/#function]

[#function getUserPoolSMSConfiguration snsId externalId ]
    [#return
        {
            "SnsCallerArn" : snsId,
            "ExternalId" : externalId
        }
    ]
[/#function]

[#function getUserPoolSchemaObject name, datatype, mutable, required]
    [#return
        [
            {
                "Name" : name,
                "AttributeDataType" : datatype,
                "Mutable" : mutable,
                "Required" : required
            }
        ]
    ]
[/#function]

[#function getUserPoolAutoVerification email=false phone=false ]
    [#assign autoVerifyArray=[]]

    [#if email ]
        [#assign autoVerifyArray = autoVerifyArray + [ "email" ] ]
    [/#if]

    [#if phone ]
        [#assign autoVerifyArray = autoVerifyArray + [ "phone_number" ]]
    [/#if]

    [#return
        autoVerifyArray
    ]
[/#function]

[#function getUserPoolInviteMessageTemplate emailMessage="" emailSubject="" smsMessage="" ]
    [#return
        {} +
        attributeIfContent(
            "EmailMessage",
            emailMessage
        ) +
        attributeIfContent(
            "EmailSubject",
            emailSubject
        ) +
        attributeIfContent(
            "SMSMessage",
            smsMessage
        )
    ]
[/#function]

[#function getUserPoolAdminCreateUserConfig enabled inviteMessageTemplate={} ]
    [#return
        {
            "AllowAdminCreateUserOnly" : enabled
        }   +
            attributeIfContent(
                "InviteMessageTemplate",
                inviteMessageTemplate
            )
    ]
[/#function]

[#function getIdentityPoolCognitoProvider userPool userPoolClient ]

    [#return
        [
            {
                "ProviderName" : userPool,
                "ClientId" : userPoolClient,
                "ServerSideTokenCheck" : true
            }
        ]
    ]
[/#function]


[#function getIdentityPoolMappingRule priority claim matchType value roleId ]
    [#return
        [
            {
                "Priority" : priority,
                "Rule" :  {
                    "Claim" : claim,
                    "MatchType" : matchType,
                    "RoleARN" : getArn( roleId ),
                    "Value" : value
                }
            }

        ]
    ]
[/#function]

[#function getIdentityPoolRoleMapping provider mappingType mappingRules matchBehaviour ]

    [#switch matchBehaviour ]
        [#case "UseAuthenticatedRule" ]
            [#local matchBehaviour = "AuthenticatedRole"]
            [#break]
        [#default]
            [#local matchBehaviour = "Deny" ]
    [/#switch]

    [#return
        {
            provider : {
                "AmbiguousRoleResolution" : matchBehaviour,
                "RulesConfiguration" : {
                    "Rules" : mappingRules
                },
                "Type" : mappingType
            }
        }
    ]
[/#function]

[#macro createUserPool id name
    mfa
    adminCreatesUser
    tags
    smsVerificationMessage=""
    emailVerificationMessage=""
    emailVerificationSubject=""
    smsInviteMessage=""
    emailInviteMessage=""
    emailInviteSubject=""
    smsAuthenticationMessage=""
    tier=""
    component=""
    loginAliases=[]
    autoVerify=[]
    schema=[]
    smsConfiguration={}
    passwordPolicy={}
    lambdaTriggers={}
    dependencies=""
    outputId=""
]

    [#-- Convert Tag Array to String Map --]
    [#local tagMap={}]
    [#list tags as tag]
        [#local tagMap = tagMap +
            { tag.Key, tag.Value }
        ]
    [/#list]

    [@cfResource
        id=id
        type="AWS::Cognito::UserPool"
        properties=
            {
                "UserPoolName" : name,
                "UserPoolTags" : tagMap,
                "MfaConfiguration" : mfa,
                "AdminCreateUserConfig" : getUserPoolAdminCreateUserConfig(
                                                adminCreatesUser,
                                                getUserPoolInviteMessageTemplate(
                                                    emailInviteMessage,
                                                    emailInviteSubject,
                                                    smsInviteMessage))
            } +
            attributeIfContent(
                "Policies",
                passwordPolicy
            ) +
            attributeIfContent(
                "AliasAttributes",
                loginAliases
            ) +
            attributeIfContent(
                "AutoVerifiedAttributes",
                autoVerify
            ) +
            attributeIfContent(
                "SmsConfiguration",
                smsConfiguration
            ) +
            attributeIfContent(
                "Schema",
                schema
            ) +
            attributeIfContent (
                "EmailVerificationMessage"
                emailVerificationMessage
            ) +
            attributeIfContent (
                "EmailVerificationSubject",
                emailVerificationSubject
             ) +
             attributeIfContent (
                "SmsVerificationMessage",
                smsVerificationMessage
             ) +
             attributeIfContent(
                 "SmsAuthenticationMessage",
                 smsAuthenticationMessage
             ) +
             attributeIfContent (
                "LambdaConfig",
                lambdaTriggers
             )
        outputs=USERPOOL_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]

[#macro createUserPoolClient id name
        userPoolId
        generateSecret=false
        tokenValidity=30
        tier=""
        component=""
        dependencies=""
        outputId=""
]

    [@cfResource
        id=id
        type="AWS::Cognito::UserPoolClient"
        properties=
            {
                "ClientName" : name,
                "GenerateSecret" : generateSecret,
                "RefreshTokenValidity" : tokenValidity,
                "UserPoolId" : getReference(userPoolId)
            }
        outputs=USERPOOL_CLIENT_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]

[#macro createIdentityPool id name
    cognitoIdProviders
    allowUnauthenticatedIdentities=false
    tier=""
    component=""
    dependencies=""
    outputId=""
]

    [@cfResource
       id=id
        type="AWS::Cognito::IdentityPool"
        properties=
            {
                "IdentityPoolName" : name,
                "AllowUnauthenticatedIdentities" : allowUnauthenticatedIdentities,
                "CognitoIdentityProviders" : asArray(cognitoIdProviders)
            }
        outputs=USERPOOL_IDENTITY_POOL_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]

[#macro createIdentityPoolRoleMapping id
    identityPoolId,
    roleMappings={},
    authenticatedRoleId="",
    unauthenticatedRoleId="",
    dependencies=""
    outputId=""
]
    [@cfResource
        id=id
        type="AWS::Cognito::IdentityPoolRoleAttachment"
        properties=
            {
                "IdentityPoolId" : getReference(identityPoolId)
            } +
            attributeIfTrue(
                "Roles",
                ( authenticatedRoleId?has_content || unauthenticatedRoleId?has_content ),
                {} +
                attributeIfContent(
                    "authenticated",
                    getArn(authenticatedRoleId)
                ) +
                attributeIfContent(
                    "unauthenticated",
                    getArn(unauthenticatedRoleId)
                )
            ) +
            attributeIfContent(
                "RoleMappings",
                roleMappings
            )
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]
