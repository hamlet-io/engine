[#-- Cognito User Pool --]
[#if (componentType == "userpool") && deploymentSubsetRequired("userpool", true)]

    [#list requiredOccurrences(
        getOccurrences(tier, component),
        deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core]
        [#assign solution = occurrence.Configuration.Solution]
        [#assign resources = occurrence.State.Resources]

        [#assign userPoolId = resources["userpool"].Id]
        [#assign userPoolName = resources["userpool"].Name]
        [#assign userPoolClientId = resources["client"].Id]
        [#assign userPoolClientName = resources["client"].Name]
        [#assign userPoolRoleId = resources["userpoolrole"].Id]
        [#assign identityPoolId = resources["identitypool"].Id]
        [#assign identityPoolName = resources["identitypool"].Name]
        [#assign identityPoolUnAuthRoleId = resources["unauthrole"].Id]
        [#assign identityPoolAuthRoleId = resources["authrole"].Id]
        [#assign identityPoolRoleMappingId = resources["rolemapping"].Id]

        [#assign dependencies = []]
        [#assign smsVerification = false]
        [#assign schema = []]
        [#assign userPoolTriggerConfig = {}]

        [#assign emailVerificationMessage =
            getOccurrenceSettingValue(occurrence, [UserPool, EmailVerificationMessage], true) ]

        [#assign emailVerificationSubject =
            getOccurrenceSettingValue(occurrence, [UserPool, EmailVerificationSubject], true) ]

        [#assign smsVerificationMessage =
            getOccurrenceSettingValue(occurrence, [UserPool, SMSVerificationMessage], true) ]

        [#assign emailInviteMessage =
            getOccurrenceSettingValue(occurrence, [UserPool, EmailInviteMessage], true) ]

        [#assign emailInviteSubject =
            getOccurrenceSettingValue(occurrence, [UserPool, EmailInviteSubject], true) ]

        [#assign smsInviteMessage =
            getOccurrenceSettingValue(occurrence, [UserPool, SMSInviteMessage], true) ]

        [#if ((solution.MFA) || ( solution.VerifyPhone))]
            [#if deploymentSubsetRequired("iam", true) &&
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

        [#if solution.VerifyEmail || ( solution.LoginAliases.seq_contains("email"))]
                [#assign emailSchema = getUserPoolSchemaObject(
                                            "email",
                                            "String",
                                            true,
                                            true)]
                [#assign schema = schema +  [ emailSchema ]]
        [/#if]

        [#list solution.Links?values as link]
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
                                [#assign userPoolTriggerConfig =  userPoolTriggerConfig +
                                    attributeIfContent (
                                        "CreateAuthChallenge",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                            [#case "custommessage"]
                                [#assign userPoolTriggerConfig = userPoolTriggerConfig +
                                    attributeIfContent (
                                        "CustomMessage",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                            [#case "defineauthchallenge"]
                                [#assign userPoolTriggerConfig = userPoolTriggerConfig +
                                    attributeIfContent (
                                        "DefineAuthChallenge",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                            [#case "postauthentication"]
                                [#assign userPoolTriggerConfig = userPoolTriggerConfig +
                                    attributeIfContent (
                                        "PostAuthentication",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                            [#case "postconfirmation"]
                                [#assign userPoolTriggerConfig = userPoolTriggerConfig +
                                    attributeIfContent (
                                        "PostConfirmation",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                            [#case "preauthentication"]
                                [#assign userPoolTriggerConfig =  userPoolTriggerConfig +
                                    attributeIfContent (
                                        "PreAuthentication",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                            [#case "presignup"]
                                [#assign userPoolTriggerConfig = userPoolTriggerConfig +
                                    attributeIfContent (
                                        "PreSignUp",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                            [#case "verifyauthchallengeresponse"]
                                [#assign userPoolTriggerConfig = userPoolTriggerConfig +
                                    attributeIfContent (
                                        "VerifyAuthChallengeResponse",
                                        linkTargetAttributes.ARN
                                    )
                                ]
                                [#break]
                        [/#switch]
                    [/#if]
                    [#break]
            [/#switch]
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
            mfa=solution.MFA
            adminCreatesUser=solution.AdminCreatesUser
            unusedTimeout=solution.UnusedAccountTimeout
            schema=schema
            emailVerificationMessage=emailVerificationMessage
            emailVerificationSubject=emailVerificationSubject
            smsVerificationMessage=smsVerificationMessage
            emailInviteMessage=emailInviteMessage
            emailInviteSubject=emailInviteSubject
            smsInviteMessage=smsInviteMessage
            lambdaTriggers=userPoolTriggerConfig
            autoVerify=(solution.VerifyEmail || smsVerification)?then(
                getUserPoolAutoVerification(solution.VerifyEmail, smsVerification),
                []
            )
            loginAliases=((solution.LoginAliases)?has_content)?then(
                    [solution.LoginAliases],
                    [])
            passwordPolicy=getUserPoolPasswordPolicy(
                    solution.PasswordPolicy.MinimumLength,
                    solution.PasswordPolicy.Lowercase,
                    solution.PasswordPolicy.Uppsercase,
                    solution.PasswordPolicy.Numbers,
                    solution.PasswordPolicy.SpecialCharacters)
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
            generateSecret=solution.ClientGenerateSecret
            tokenValidity=solution.ClientTokenValidity
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
            allowUnauthenticatedIdentities=solution.AllowUnauthenticatedIds
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