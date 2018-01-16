[#assign USERPOOL_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        NAME_ATTRIBUTE_TYPE : { 
            "Attribute" : ProviderName
        },
        ARN_ATTRIBUTE_TYPE : { 
            "Attribute" : "Arn"
        },
        URL_ATTRIBUTE_TYPE : { 
            "Attribute" : "ProviderURL"
        }
    }
]

[#macro createUserPool mode id name tier="" component="" lifecycleRules=[] sqsNotifications=[] websiteConfiguration={} dependencies="" outputId=""]
    [@cfResource 
        mode=mode
        id=id
        type="AWS::Cognito::UserPool"
        properties=
            {
                "UserPoolName" : name,
                "AutoVerifiedAttributes" : [
                    "email"
                ],
                "MfaConfiguration" : "OFF",
                "AdminCreateUserConfig" : {
                    "AllowAdminCreateUserOnly" : true,
                    "UnusedAccountValidityDays" : 14
                },
                "DeviceConfiguration" : {
                    "ChallengeRequiredOnNewDevice" : false,
                    "DeviceOnlyRememberedOnUserPrompt" : false
                },
                "Policies" : [
                    {
                        "PasswordPolicy" : {
                            "MinimumLength" : 8,
                            "RequireLowercase": true,
                            "RequireUppercase" : true,
                            "RequireNumbers" : true
                        }
                    }
                ],
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
            } 
        tags=getCfTemplateCoreTags("", tier, component)
        outputs=S3_OUTPUT_MAPPINGS
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]