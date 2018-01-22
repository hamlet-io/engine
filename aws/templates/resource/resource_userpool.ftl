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