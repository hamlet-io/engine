[#-- Cognito User Pool --]
[#if (componentType == "userpool") && deploymentSubsetRequired("userpool", true)]
    
    [#list requiredOccurrences(
        getOccurrences(tier, component),
        deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign configuration = occurrence.Configuration ]

        [#assign userPoolId = formatUserPoolId(tier, component, occurrence)]
        [#assign userPoolClientId = formatUserPoolClientId(tier, component, occurrence)]
        [#assign userPoolRoleId = formatComponentRoleId(tier, component, occurrence)]
        [#assign identityPoolId = formatIdentityPoolId(tier,component, occurrence)]
        [#assign identityPoolUnAuthRoleId = formatDependentIdentityPoolUnAuthRoleId(identityPoolId)]
        [#assign identityPoolAuthRoleId = formatDependentIdentityPoolAuthRoleId(identityPoolId)]
        [#assign identityPoolRoleMappingId = formatDependentIdentityPoolRoleMappingId(identityPoolId)]
        [#assign userPoolName = formatUserPoolName(tier, component, occurrence)]
        [#assign identityPoolName = formatIdentityPoolName(tier, component, occurrence)]
        [#assign userPoolClientName = formatUserPoolClientName(tier, component, occurrence) ]
        [#assign dependencies = [] ]
        [#assign smsVerification = false]
        [#assign schema = [] ]
        [#assign userPoolTriggerConfig = {} ]

        [@cfDebug listMode appSettingsObject false /]

        [#assign emailVerificationMessage = ""]
        [#if (appSettingsObject.UserPool.EmailVerificationMessage)?has_content ]
            [#assign emailVerificationMessage = appSettingsObject.UserPool.EmailVerificationMessage ]
        [/#if]

        [#assign emailVerificationSubject = ""]
        [#if (appSettingsObject.UserPool.EmailVerificationSubject)?has_content ]
            [#assign emailVerificationSubject = appSettingsObject.UserPool.EmailVerificationSubject ]
        [/#if]

        [#assign smsVerificationMessage = ""]
        [#if (appSettingsObject.UserPool.SMSVerificationMessage)?has_content ]
            [#assign emailVerificationSubject = appSettingsObject.UserPool.SMSVerificationMessage ]
        [/#if]

        [#assign emailInviteMessage = "" ]
        [#if (appSettingsObject.UserPool.EmailInviteMessage)?has_content ]
            [#assign emailInviteMessage = appSettingsObject.UserPool.EmailInviteMessage ]
        [/#if]

        [#assign emailInviteSubject = "" ]
        [#if (appSettingsObject.UserPool.EmailInviteSubject)?has_content ]
            [#assign emailInviteSubject = appSettingsObject.UserPool.EmailInviteSubject ]
        [/#if]

        [#assign smsInviteMessage = ""] 
        [#if (appSettingsObject.UserPool.SMSInviteMessage)?has_content ]
            [#assign smsInviteMessage = appSettingsObject.UserPool.SMSInviteMessage ]
        [/#if]

        [#if ( (configuration.MFA) || ( configuration.verifyPhone)) ]
            [#if deploymentSubsetRequired("iam", true) &&
            isPartOfCurrentDeploymentUnit(userPoolId) ]

                [@createRole
                    mode=listMode
                    id=userPoolRoleId
                    trustedServices=["cognito-idp.amazonaws.com" ]
                    policies=
                        [
                            getPolicyDocument(
                                snsPublishPermission(),
                                "smsVerification" 
                            )
                        ]
                /]

                [#assign phoneSchema = getUserPoolSchemaObject( 
                                            "phone_number",
                                            "String",
                                            true,
                                            true)]
                [#assign schema = schema + [ phoneSchema ]]

                )]

            [/#if]

            [#assign smsConfig = getUserPoolSMSConfiguration( getReference(userPoolRoleId, ARN_ATTRIBUTE_TYPE), userPoolName )]
            [#assign smsVerification = true]
        [/#if]

        [#if configuration.verifyEmail || ( configuration.loginAliases.seq_contains("email") ) ]
                [#assign emailSchema = getUserPoolSchemaObject( 
                                            "email",
                                            "String",
                                            true,
                                            true)]
                [#assign schema = schema +  [ emailSchema ]]
        [/#if]

        [#list configuration.Links?values as link]
            [#if link?is_hash]
                [#assign linkTarget = getLinkTarget(occurrence, link, true) ]
                [@cfDebug listMode linkTarget false /]

                [#assign linkTargetCore = linkTarget.Core ]
                [#assign linkTargetConfiguration = linkTarget.Configuration ]
                [#assign linkTargetResources = linkTarget.State.Resources ]
                [#assign linkTargetAttributes = linkTarget.State.Attributes ]

                [#switch linkTargetCore.Type!""]
                    [#case LAMBDA_FUNCTION_COMPONENT_TYPE ]

                        [#-- Cognito Userpool Event Triggers --]
                        [#switch link.Name ]
                            [#case "createauthchallenge" ]
                                [#assign userPoolTriggerConfig =  userPoolTriggerConfig +
                                    attributeIfContent (
                                        "CreateAuthChallenge",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                            [#break]
                            [#case "custommessage" ]
                                [#assign userPoolTriggerConfig = userPoolTriggerConfig +
                                    attributeIfContent (
                                        "CustomMessage",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                            [#break]
                            [#case "defineauthchallenge" ]
                                [#assign userPoolTriggerConfig = userPoolTriggerConfig +
                                    attributeIfContent (
                                        "DefineAuthChallenge",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                            [#break]
                            [#case "postauthentication" ]
                                [#assign userPoolTriggerConfig = userPoolTriggerConfig +
                                    attributeIfContent (
                                        "PostAuthentication",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                            [#break]
                            [#case "postconfirmation" ]
                                [#assign userPoolTriggerConfig = userPoolTriggerConfig +
                                    attributeIfContent (
                                        "PostConfirmation",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                            [#break]
                            [#case "preauthentication" ]
                                [#assign userPoolTriggerConfig =  userPoolTriggerConfig +
                                    attributeIfContent (
                                        "PreAuthentication",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                            [#break]
                            [#case "presignup" ]
                                [#assign userPoolTriggerConfig = userPoolTriggerConfig + 
                                    attributeIfContent (
                                        "PreSignUp",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                            [#break]
                            [#case "verifyauthchallengeresponse" ]
                                [#assign userPoolTriggerConfig = userPoolTriggerConfig + 
                                    attributeIfContent (
                                        "VerifyAuthChallengeResponse",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                            [#break]
                        [/#switch]
                    [#break]
                [/#switch]
            [/#if]
        [/#list]

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
            adminCreatesUser=configuration.adminCreatesUser
            unusedTimeout=configuration.unusedAccountTimeout
            schema=schema
            emailVerificationMessage=emailVerificationMessage
            emailVerificationSubject=emailVerificationSubject
            smsVerificationMessage=smsVerificationMessage
            emailInviteMessage=emailInviteMessage
            emailInviteSubject=emailInviteSubject
            smsInviteMessage=smsInviteMessage
            lambdaTriggers=userPoolTriggerConfig
            autoVerify=(configuration.verifyEmail || smsVerification)?then(
                getUserPoolAutoVerification(configuration.verifyEmail, smsVerification),
                []
            )
            loginAliases=((configuration.loginAliases)?has_content)?then(
                    [configuration.loginAliases],
                    [])
            passwordPolicy=getUserPoolPasswordPolicy( 
                    configuration.passwordPolicy.minimumLength, 
                    configuration.passwordPolicy.lowercase,
                    configuration.passwordPolicy.uppsercase,
                    configuration.passwordPolicy.numbers,
                    configuration.passwordPolicy.specialCharacters)
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
            generateSecret=configuration.clientGenerateSecret
            tokenValidity=configuration.clientTokenValidity
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
            allowUnauthenticatedIdentities=configuration.allowUnauthenticatedIds
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
    [/#list]
[/#if]