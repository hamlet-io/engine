[#-- Cognito User Pool --]
[#if componentType == USERPOOL_COMPONENT_TYPE ]
    
    [#list requiredOccurrences(
        getOccurrences(tier, component),
        deploymentUnit) as occurrence]
        
        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core]
        [#assign solution = occurrence.Configuration.Solution]
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
        [#assign smsConfig = {}]
        
        [#assign userPoolUpdateCommand = "updateUserPool" ]            
    
        [@cfDebug listMode appSettingsObject false /]

        [#assign emailVerificationMessage =
            getOccurrenceSettingValue(occurrence, ["UserPool", "EmailVerificationMessage"], true) ]

        [#assign emailVerificationSubject =
            getOccurrenceSettingValue(occurrence, ["UserPool", "EmailVerificationSubject"], true) ]

        [#assign smsVerificationMessage =
            getOccurrenceSettingValue(occurrence, ["UserPool", "SMSVerificationMessage"], true) ]

        [#assign emailInviteMessage =
            getOccurrenceSettingValue(occurrence, ["UserPool", "EmailInviteMessage"], true) ]

        [#assign emailInviteSubject =
            getOccurrenceSettingValue(occurrence, ["UserPool", "EmailInviteSubject"], true) ]

        [#assign smsInviteMessage =
            getOccurrenceSettingValue(occurrence, ["UserPool", "SMSInviteMessage"], true) ]

        [#if ((solution.MFA) || ( solution.VerifyPhone))]

            [#assign phoneSchema = getUserPoolSchemaObject( 
                                        "phone_number",
                                        "String",
                                        true,
                                        true)]
            [#assign schema = schema + [ phoneSchema ]]

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
                        [#-- TODO: When all Cognito Events are available via Cloudformation update the userPoolManualTriggerConfig to userPoolTriggerConfig --]
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

        [#if ((solution.MFA) || ( solution.VerifyPhone))]
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
        [/#if]

        [#-- When using the cli to update a user pool, any properties that are not set in the update are reset to their default value --]
        [#-- So to use the CLI to update the lambda triggers we need to generate all of the custom configuration we use in the CF template and use this as the update --]
        [#if deploymentSubsetRequired("cli", false)]

            [#assign userpoolConfig = {
                "UserPoolId": getExistingReference(userPoolId),
                "Policies": getUserPoolPasswordPolicy( 
                        configuration.PasswordPolicy.MinimumLength, 
                        configuration.PasswordPolicy.Lowercase,
                        configuration.PasswordPolicy.Uppsercase,
                        configuration.PasswordPolicy.Numbers,
                        configuration.PasswordPolicy.SpecialCharacters),
                "MfaConfiguration": configuration.MFA?then("ON","OFF"),
                "UserPoolTags": getCfTemplateCoreTags(
                                    userPoolName,
                                    tier,
                                    component,
                                    ""
                                    false,
                                    true),
                "AdminCreateUserConfig": getUserPoolAdminCreateUserConfig(
                                                configuration.AdminCreatesUser, 
                                                configuration.UnusedAccountTimeout,
                                                getUserPoolInviteMessageTemplate(
                                                    emailInviteMessage,
                                                    emailInviteSubject,
                                                    smsInviteMessage))
            } +
            attributeIfContent(
                "SmsVerificationMessage",
                smsVerificationMessage
            ) +
            attributeIfContent(
                "EmailVerificationMessage",
                emailVerificationMessage
            ) +
            attributeIfContent(
                "EmailVerificationSubject",
                emailVerificationSubject
            ) + 
            attributeIfContent(
                "SmsConfiguration",
                smsConfig
            ) +
            attributeIfTrue(
                "AutoVerifiedAttributes",
                (configuration.VerifyEmail || smsVerification),
                getUserPoolAutoVerification(configuration.VerifyEmail, smsVerification)
            ) +
            attributeIfTrue(
                "LambdaConfig",
                (userPoolTriggerConfig?has_content || userPoolManualTriggerConfig?has_content ),
                userPoolTriggerConfig + userPoolManualTriggerConfig
            )]

            [#if userPoolManualTriggerConfig?has_content ]
                [@cfCli
                    mode=listMode
                    id=userPoolId
                    command=userPoolUpdateCommand
                    content=userpoolConfig
                /]
            [/#if]
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
                        "# Get cli config file",
                        "split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?", 
                        "update_cognito_userpool" +
                        " \"" + region + "\" " + 
                        " \"" + getExistingReference(userPoolId) + "\" " + 
                        " \"$\{tmpdir}/cli-" + 
                        userPoolId + "-" + userPoolUpdateCommand + ".json\" || return $?"
                    ],
                    []
                )
            /]
        [/#if]
    [/#list]
[/#if]