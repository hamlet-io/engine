[#-- Cognito User Pool --]
[#if componentType == USERPOOL_COMPONENT_TYPE ]
    
    [#list requiredOccurrences(
        getOccurrences(tier, component),
        deploymentUnit) as occurrence]
        
        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core]
        [#assign configuration = occurrence.Configuration]
        [#assign resources = occurrence.State.Resources]

        [#assign userPoolId                 = resources["userpool"].Id]
        [#assign userPoolName               = resources["userpool"].Name]
        [#assign userPoolClientId           = resources["client"].Id]
        [#assign userPoolClientName         = resources["client"].Name]
        [#assign userPoolRoleId             = resources["userpoolrole"].Id]
        [#assign identityPoolId             = resources["identitypool"].Id]
        [#assign identityPoolName           = resources["identitypool"].Name]
        [#assign identityPoolUnAuthRoleId   = resources["unauthrole"].Id]
        [#assign identityPoolAuthRoleId     = resources["authrole"].Id]
        [#assign identityPoolRoleMappingId  = resources["rolemapping"].Id]

        [#assign dependencies = []]
        [#assign smsVerification = false]
        [#assign schema = []]
        [#assign userPoolTriggerConfig = {}]
        [#assign userPoolManualTriggerConfig = {}]
                
        [@cfDebug listMode appSettingsObject false /]

        [#assign emailVerificationMessage =
            valueIfContent(
            appSettingsObject.UserPool.EmailVerificationMessage!"",
            appSettingsObject.UserPool.EmailVerificationMessage!"",
            "")]

            
        [#assign emailVerificationSubject =
            valueIfContent(
            appSettingsObject.UserPool.EmailVerificationSubject!"",
            appSettingsObject.UserPool.EmailVerificationSubject!"",
            "")]

        [#assign smsVerificationMessage =
            valueIfContent(
            appSettingsObject.UserPool.SMSVerificationMessage!"",
            appSettingsObject.UserPool.SMSVerificationMessage!"",
            "")]

        [#assign emailInviteMessage =
            valueIfContent(
            appSettingsObject.UserPool.EmailInviteMessage!"",
            appSettingsObject.UserPool.EmailInviteMessage!"",
            "")]

        [#assign emailInviteSubject =
            valueIfContent(
            appSettingsObject.UserPool.EmailInviteSubject!"",
            appSettingsObject.UserPool.EmailInviteSubject!"",
            "")]

        [#assign smsInviteMessage =
            valueIfContent(
            appSettingsObject.UserPool.SMSInviteMessage!"",
            appSettingsObject.UserPool.SMSInviteMessage!"",
            "")]

        [#if ((configuration.MFA) || ( configuration.VerifyPhone))]

            [#assign phoneSchema = getUserPoolSchemaObject( 
                                        "phone_number",
                                        "String",
                                        true,
                                        true)]
            [#assign schema = schema + [ phoneSchema ]]

            [#assign smsConfig = getUserPoolSMSConfiguration( getReference(userPoolRoleId, ARN_ATTRIBUTE_TYPE), userPoolName )]
            [#assign smsVerification = true]
        [/#if]

        [#if configuration.VerifyEmail || ( configuration.LoginAliases.seq_contains("email"))]
                    [#assign emailSchema = getUserPoolSchemaObject( 
                                                "email",
                                                "String",
                                                true,
                                                true)]
                    [#assign schema = schema +  [ emailSchema ]]
        [/#if]

        [#list configuration.Links?values as link]
            [#assign linkTarget = getLinkTarget(occurrence, link)]

            [@cfDebug listMode linkTarget false /]

            [#if !linkTarget?has_content]
                [#continue]
            [/#if]

            [#assign linkTargetCore = linkTarget.Core]
            [#assign linkTargetConfiguration = linkTarget.Configuration]
            [#assign linkTargetResources = linkTarget.State.Resources]
            [#assign linkTargetAttributes = linkTarget.State.Attributes]

            [#switch linkTargetCore.Type]
                [#case LAMBDA_FUNCTION_COMPONENT_TYPE]
                    
                    [#if linkTargetResources[LAMBDA_FUNCTION_COMPONENT_TYPE].Deployed]
                        [#-- Cognito Userpool Event Triggers --]
                        [#switch link.Name?lower_case]
                            [#case "createauthchallenge"]
                                [#assign userPoolTriggerConfig +=
                                    attributeIfContent (
                                        "CreateAuthChallenge",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                            [#case "custommessage"]
                                [#assign userPoolTriggerConfig +=
                                    attributeIfContent (
                                        "CustomMessage",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                            [#case "defineauthchallenge"]
                                [#assign userPoolTriggerConfig +=
                                    attributeIfContent (
                                        "DefineAuthChallenge",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                            [#case "postauthentication"]
                                [#assign userPoolTriggerConfig +=
                                    attributeIfContent (
                                        "PostAuthentication",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                            [#case "postconfirmation"]
                                [#assign userPoolTriggerConfig +=
                                    attributeIfContent (
                                        "PostConfirmation",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                            [#case "preauthentication"]
                                [#assign userPoolTriggerConfig +=
                                    attributeIfContent (
                                        "PreAuthentication",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                            [#case "presignup"]
                                [#assign userPoolTriggerConfig += 
                                    attributeIfContent (
                                        "PreSignUp",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                            [#case "verifyauthchallengeresponse"]
                                [#assign userPoolTriggerConfig += 
                                    attributeIfContent (
                                        "VerifyAuthChallengeResponse",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                            [#case "pretokengeneration"]
                                [#assign userPoolManualTriggerConfig +=
                                    attributeIfContent (
                                        "PreTokenGeneration",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                            [#case "usermigration"]
                                [#assign userPoolManualTriggerConfig +=
                                    attributeIfContent (
                                        "UserMigration",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                        [/#switch]
                    [/#if]
                [#break]
            [/#switch]
        [/#list]

        [#assign userPoolManualTriggerString = [] ] 
        [#list userPoolManualTriggerConfig as key,value ]
            [#assign userPoolManualTriggerString += [ key + "=" + value ]]
        [/#list]

        [#assign userPoolManualTriggerString = userPoolManualTriggerString?join(",")]

        [#if ((configuration.MFA) || ( configuration.VerifyPhone))]
            [#if (deploymentSubsetRequired("iam", true) || deploymentSubsetRequired("userpool", true)) &&
                isPartOfCurrentDeploymentUnit(userPoolId)]

                    [@createRole
                        mode=listMode
                        id=userPoolRoleId
                        trustedServices=["cognito-idp.amazonaws.com"]
                        policies=
                            [
                                getPolicyDocument(
                                    snsPublishPermission(),
                                    "smsVerification" 
                                )
                            ]
                    /]


                )]

            [/#if]
        [/#if]

        [#if deploymentSubsetRequired("userpool", true) ]
            [@createUserPool 
                mode=listMode
                component=component
                tier=tier
                id=userPoolId
                name=userPoolName
                tags=getCfTemplateCoreTags(
                        userPoolName,
                        tier,
                        component)
                dependencies=dependencies
                mfa=configuration.MFA
                adminCreatesUser=configuration.AdminCreatesUser
                unusedTimeout=configuration.UnusedAccountTimeout
                schema=schema
                emailVerificationMessage=emailVerificationMessage
                emailVerificationSubject=emailVerificationSubject
                smsVerificationMessage=smsVerificationMessage
                emailInviteMessage=emailInviteMessage
                emailInviteSubject=emailInviteSubject
                smsInviteMessage=smsInviteMessage
                lambdaTriggers=userPoolTriggerConfig
                autoVerify=(configuration.VerifyEmail || smsVerification)?then(
                    getUserPoolAutoVerification(configuration.VerifyEmail, smsVerification),
                    []
                )
                loginAliases=((configuration.LoginAliases)?has_content)?then(
                        [configuration.LoginAliases],
                        [])
                passwordPolicy=getUserPoolPasswordPolicy( 
                        configuration.PasswordPolicy.MinimumLength, 
                        configuration.PasswordPolicy.Lowercase,
                        configuration.PasswordPolicy.Uppsercase,
                        configuration.PasswordPolicy.Numbers,
                        configuration.PasswordPolicy.SpecialCharacters)
                smsConfiguration=((smsConfig)?has_content)?then(
                    smsConfig,
                    {})
            /]

            [@createUserPoolClient 
                mode=listMode
                component=component
                tier=tier
                dependencies=dependencies
                id=userPoolClientId
                name=userPoolClientName
                userPoolId=userPoolId
                generateSecret=configuration.ClientGenerateSecret
                tokenValidity=configuration.ClientTokenValidity
            /]

            [#assign cognitoIdentityPoolProvider = getIdentityPoolCognitoProvider( userPoolId, userPoolClientId )]

            [@createIdentityPool 
                mode=listMode
                component=component
                tier=tier
                dependencies=dependencies
                id=identityPoolId
                name=identityPoolName
                cognitoIdProviders=cognitoIdentityPoolProvider
                allowUnauthenticatedIdentities=configuration.AllowUnauthenticatedIds
            /]

            [@createRole
                mode=listMode
                id=identityPoolUnAuthRoleId
                policies=[
                    getPolicyDocument(
                        getUserPoolUnAuthPolicy(),
                        "DefaultUnAuthIdentityRole"
                    )
                ]
                federatedServices="cognito-identity.amazonaws.com"
                condition={
                    "StringEquals": {
                        "cognito-identity.amazonaws.com:aud": getReference(identityPoolId)
                    },
                    "ForAnyValue:StringLike": {
                        "cognito-identity.amazonaws.com:amr": "unauthenticated"
                    }
                }
            /]

            [@createRole 
                mode=listMode
                id=identityPoolAuthRoleId
                policies=[
                    getPolicyDocument(
                        getUserPoolAuthPolicy(),
                        "DefaultAuthIdentityRole"
                    )
                ]
                federatedServices="cognito-identity.amazonaws.com"
                condition={
                    "StringEquals": {
                        "cognito-identity.amazonaws.com:aud": getReference(identityPoolId)
                    },
                    "ForAnyValue:StringLike": {
                        "cognito-identity.amazonaws.com:amr": "authenticated"
                    }
                }
            /]

            [@createIdentityPoolRoleMapping
                mode=listMode
                component=component
                tier=tier
                id=identityPoolRoleMappingId
                identityPoolId=getReference(identityPoolId)
                authenticatedRoleArn=getReference(identityPoolAuthRoleId, ARN_ATTRIBUTE_TYPE)
                unauthenticatedRoleArn=getReference(identityPoolUnAuthRoleId, ARN_ATTRIBUTE_TYPE)
            /]
        [/#if]
        
        [#if deploymentSubsetRequired("epilogue", false)]
            [@cfScript
                mode=listMode
                content=
                [#-- Some Userpool Lambda triggers are not available via Cloudformation but are available via CLI --]
                (userPoolManualTriggerConfig?has_content)?then(
                    [
                        "# Add Manual Cognito Triggers",
                        "info \"Adding Cognito Triggers that are not part of cloudformation\""
                        "add_cognito_lambda_triggers" +
                        " \"" + region + "\" " + 
                        " \"" + getExistingReference(userPoolId) + "\" " + 
                        " \"" + userPoolManualTriggerString + "\" " + 
                        " || return $?"
                    ],
                    []
                )
            /]
        [/#if]
    [/#list]
[/#if]