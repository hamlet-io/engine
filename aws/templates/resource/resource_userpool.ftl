[#-- Cognito User Pool --]

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
        }
    }
]

[#assign USERPOOL_CLIENT_OUTPUT_MAPPINGS = 
    { 
        REFERENCE_ATTRIBUTE_TYPE : { 
            "UserRef" : true
        },
        NAME_ATTRIBUTE_TYPE : { 
            "Attribute" : "Name" 
        }
    }
]

[#assign USERPOOL_IDENTITYPOOL_OUTPUT_MAPPINGS = 
    {
        REFERENCE_ATTRIBUTE_TYPE : { 
            "UseRef" : true
        },
        NAME_ATTRIBUTE_TYPE : {
            "Attribute" : "Name"
        }
    }
]

[#assign outputMappings +=
    {
        USERPOOL_RESOURCE_TYPE : USERPOOL_OUTPUT_MAPPINGS,
        USERPOOL_CLIENT_RESOURCE_TYPE : USERPOOL_CLIENT_OUTPUT_MAPPINGS,
        USERPOOL_IDENTITYPOOL_RESOURCE_TYPE : USERPOOL_IDENTITYPOOL_OUTPUT_MAPPINGS
    }
]

[#function getUserPoolPasswordPolicy length="8" lowercase=true uppercase=true numbers=true symbols=true]
    [#return 
        {
            "PasswordPolicy" : {
                "MinimumLength"     : length,
                "RequireLowercase"  : lowercase,
                "RequireUppercase"  : uppercase,
                "RequireNumbers"    : numbers,
                "RequireSymbols"    : symbols
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

[#function getUserPoolAutoVerifcation email=false phone=false ]
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

[#function getIdentityPoolCognitoProvider UserPoolId userPoolClientId serverSideToken=true ]

    [#assign userPoolRef = getReference(UserPoolId, NAME_ATTRIBUTE_TYPE)]
    [#assign userpoolClientRef = getReference(userPoolClientId )]

    [#return
        {
            "ProviderName" : userPoolRef,
            "ClientId" : userpoolClientRef,
            "ServerSideTokenCheck" : serverSideToken
        }
    ]
[/#function]

[#macro createUserPool mode id name 
    mfa
    adminCreatesUser
    unusedTimeout
    tags
    tier="" 
    component="" 
    loginAliases=[] 
    autoVerify=[]
    smsConfiguration={}
    passwordPolicy={}  
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
        mode=mode
        id=id
        type="AWS::Cognito::UserPool"
        properties=
            {
                "UserPoolName" : name,
                "UserPoolTags" : tagMap,
                "MfaConfiguration" : mfa?then("ON","OFF"),
                "AdminCreateUserConfig" : {
                    "AllowAdminCreateUserOnly" : adminCreatesUser,
                    "UnusedAccountValidityDays" : unusedTimeout
                },
                "Schema" : [
                    {
                        "AttributeDataType" : "String",
                        "Name": "email",
                        "Required" : true,
                        "Mutable" : false,
                        "StringAttributeConstraints": {
                            "MinLength" : "3" 
                        }
                    }
                ]
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
            )
        outputs=USERPOOL_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]

[#macro createUserPoolClient mode id name 
        userPoolId 
        generateSecret=false
        tokenValidity=30
        tier="" 
        component="" 
        dependencies="" 
        outputId=""
]

    [@cfResource 
        mode=mode
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

[#macro createUserPoolIdentityPool mode id name
    cognitoIdProviders
    allowUnauthenticatedIdentities=false
    tier=""
    component=""
    dependencies=""
    outputId=""
]

    [@cfResource 
        mode=mode
        id=id
        type="AWS::Cognito::IdentityPool"
        properties=
            {
                "IdentityPoolName" : name,
                "AllowUnauthenticatedIdentities" : allowUnauthenticatedIdentities,
                "CognitoIdentityProviders" : [ 
                    cognitoIdProviders
                ]
            }
        outputs=USERPOOL_IDENTITY_POOL_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]

[#macro createUserPoolIdentityPollRoleMapping mode id  
    IdentityPoolId,
    authenticatedRoleArn,
    unauthenticatedRoleArn
    tier=""
    component=""
    dependencies=""
    outputId=""
]
    [@cfResource
        mode=mode
        id=id
        type="AWS::Cognito::IdentityPoolRoleAttachment"
        properties=
            {
                "IdentityPoolId" : IdentityPoolId,
                "Roles" : { 
                    "authenticated" : authenticatedRoleArn,
                    "unauthenticated" : unauthenticatedRoleArn
                }
            }
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]

