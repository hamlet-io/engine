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
        
        [#assign userPoolDomainId           = resources["domain"].Id]
        [#assign userPoolHostName           = resources["domain"].Name]
        [#assign customDomainRequired       = ((resources["customdomain"].Id)!"")?has_content ]
        [#if customDomainRequired ]
            [#assign userPoolCustomDomainId = resources["customdomain"].Id ]
            [#assign userPoolCustomDomainName = resources["customdomain"].Name ]
            [#assign userPoolCustomDomainCertArn = resources["customdomain"].CertificateArn]
        [/#if]

        [#assign userPoolRoleId             = resources["userpoolrole"].Id]

        [#assign identityPoolId             = resources["identitypool"].Id]
        [#assign identityPoolName           = resources["identitypool"].Name]
        [#assign identityPoolUnAuthRoleId   = resources["unauthrole"].Id]
        [#assign identityPoolAuthRoleId     = resources["authrole"].Id]
        [#assign identityPoolRoleMappingId  = resources["rolemapping"].Id]

        [#assign smsVerification = false]
        [#assign userPoolTriggerConfig = {}]
        [#assign userPoolManualTriggerConfig = {}]
        [#assign smsConfig = {}]
        [#assign identityPoolProviders = []]

        [#assign defaultUserPoolClientRequried = false ]
        [#assign defaultUserPoolClientConfigured = false ]

        [#if (resources["client"]!{})?has_content]
            [#assign defaultUserPoolClientRequried = true ]
            [#assign defaultUserPoolClientId = resources["client"].Id]
        [/#if]

        [#assign userPoolUpdateCommand = "updateUserPool" ]
        [#assign userPoolClientUpdateCommand = "updateUserPoolClient" ]     
        [#assign userPoolDomainCommand = "setDomainUserPool" ]
    
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
        
        [#assign smsAuthenticationMessage =
            getOccurrenceSettingValue(occurrence, ["UserPool", "SMSAuthenticationMessage"], true) ]

        [#assign schema = []]
        [#list solution.Schema as key,schemaAttribute ]
            [#assign schema +=  getUserPoolSchemaObject(
                                key,
                                schemaAttribute.DataType,
                                schemaAttribute.Mutable,
                                schemaAttribute.Required
            )]
        [/#list]

        [#if ((solution.MFA) || ( solution.VerifyPhone))]
            [#if ! (solution.Schema["phone_number"]!"")?has_content ]
                [@cfException
                    mode=listMode
                    description="Schema Attribute required: phone_number - Add Schema listed in detail"
                    context=schema
                    detail={
                        "phone_number" : {
                            "DataType" : "String",
                            "Mutable" : true,
                            "Required" : true
                        }
                    }/]
            [/#if]

            [#assign smsConfig = getUserPoolSMSConfiguration( getReference(userPoolRoleId, ARN_ATTRIBUTE_TYPE), userPoolName )]
            [#assign smsVerification = true]
        [/#if]

        [#if solution.VerifyEmail || ( solution.LoginAliases.seq_contains("email"))]
            [#if ! (solution.Schema["email"]!"")?has_content ]
                [@cfException
                    mode=listMode
                    description="Schema Attribute required: email - Add Schema listed in detail"
                    context=schema
                    detail={
                        "email" : {
                            "DataType" : "String",
                            "Mutable" : true,
                            "Required" : true
                        }
                    }/]
            [/#if]
        [/#if]

        [#list solution.Links?values as link]
            [#assign linkTarget = getLinkTarget(occurrence, link)]

            [@cfDebug listMode linkTarget false /]

            [#if !linkTarget?has_content]
                [#continue]
            [/#if]

            [#assign linkTargetCore = linkTarget.Core]
            [#assign linkTargetConfiguration = linkTarget.Configuration ]
            [#assign linkTargetResources = linkTarget.State.Resources]
            [#assign linkTargetAttributes = linkTarget.State.Attributes]

            [#switch linkTargetCore.Type]
                    
                [#case LAMBDA_FUNCTION_COMPONENT_TYPE]

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
                [#break]
            [/#switch]
        [/#list]

        [#assign userPoolManualTriggerString = [] ] 
        [#list userPoolManualTriggerConfig as key,value ]
            [#assign userPoolManualTriggerString += [ key + "=" + value ]]
        [/#list]

        [#assign userPoolManualTriggerString = userPoolManualTriggerString?join(",")]

        [#-- Initialise epilogue script with common parameters --]
        [#if deploymentSubsetRequired("epilogue", false)]
            [@cfScript 
                mode=listMode
                content=[
                    " case $\{STACK_OPERATION} in",
                    "   create|update)",
                    "       # Get cli config file",
                    "       split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?", 
                    "       # Get userpool id",
                    "       export userPoolId=$(get_cloudformation_stack_output" +
                    "       \"" + region + "\" " + 
                    "       \"$\{STACK_NAME}\" " +
                    "       \"" + userPoolId + "\" " +
                    "       || return $?)",
                    "       ;;",
                    " esac"
                ]
            /]
        [/#if]

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
            [/#if]
        [/#if]

        [#list occurrence.Occurrences![] as subOccurrence]

            [#assign subCore = subOccurrence.Core ]
            [#assign subSolution = subOccurrence.Configuration.Solution ]
            [#assign subResources = subOccurrence.State.Resources ]

            [#if subCore.Type == USERPOOL_CLIENT_COMPONENT_TYPE]

                [#if subCore.SubComponent.Id = "default" ]
                    [#assign defaultUserPoolClientConfigured = true]
                [/#if]

                [#assign userPoolClientId           = subResources["client"].Id]
                [#assign userPoolClientName         = subResources["client"].Name]
                [#assign identityPoolProviders      += subSolution.IdentityPoolAccess?then( 
                                                        [getIdentityPoolCognitoProvider( userPoolId, userPoolClientId )],
                                                        []
                                                    )]
                
                [#assign callbackUrls = []]
                [#assign logoutUrls = []]

                [#list subSolution.Links?values as link]
                    [#assign linkTarget = getLinkTarget(subOccurrence, link)]

                    [@cfDebug listMode linkTarget false /]

                    [#if !linkTarget?has_content]
                        [#continue]
                    [/#if]

                    [#assign linkTargetCore = linkTarget.Core]
                    [#assign linkTargetConfiguration = linkTarget.Configuration ]
                    [#assign linkTargetResources = linkTarget.State.Resources]
                    [#assign linkTargetAttributes = linkTarget.State.Attributes]

                    [#switch linkTargetCore.Type]
                        [#case LB_PORT_COMPONENT_TYPE]
                            [#assign callbackUrls += [
                                linkTargetAttributes["AUTH_CALLBACK_URL"],
                                linkTargetAttributes["AUTH_CALLBACK_INTERNAL_URL"]
                                ]
                            ]
                            [#break]
                        
                        [#case "external" ]
                            [#if linkTargetAttributes["AUTH_CALLBACK_URL"]?has_content ]
                                [#assign callbackUrls += linkTargetAttributes["AUTH_CALLBACK_URL"]?split(",") ]
                            [/#if]
                            [#if linkTargetAttributes["AUTH_SIGNOUT_URL"]?has_content ]
                                [#assign logoutUrls += linkTargetAttributes["AUTH_SIGNOUT_URL"]?split(",") ]
                            [/#if]
                            [#break]

                    [/#switch]
                [/#list]

                [#if deploymentSubsetRequired(USERPOOL_COMPONENT_TYPE, true) ]
                    [@createUserPoolClient 
                        mode=listMode
                        component=component
                        tier=tier
                        id=userPoolClientId
                        name=userPoolClientName
                        userPoolId=userPoolId
                        generateSecret=subSolution.ClientGenerateSecret
                        tokenValidity=subSolution.ClientTokenValidity
                    /]
                [/#if]


                [#if deploymentSubsetRequired("cli", false)]
                    [#assign updateUserPoolClient =  {
                            "CallbackURLs": callbackUrls,
                            "LogoutURLs": logoutUrls,
                            "AllowedOAuthFlows": asArray(subSolution.OAuth.Flows),
                            "AllowedOAuthScopes": asArray(subSolution.OAuth.Scopes),
                            "AllowedOAuthFlowsUserPoolClient": true,
                            "SupportedIdentityProviders" : [ "COGNITO" ]
                        }
                    ]

                    [@cfCli
                        mode=listMode
                        id=userPoolClientId
                        command=userPoolClientUpdateCommand
                        content=updateUserPoolClient
                    /]
                [/#if]

                [#if deploymentSubsetRequired("epilogue", false)]
                    [@cfScript 
                    mode=listMode
                    content=
                        [
                            " case $\{STACK_OPERATION} in",
                            "   create|update)",
                            "       # Manage Userpool client",
                            "       info \"Applying Cli level configuration to UserPool Client - Id: " + userPoolClientId +  "\"",
                            "       export userPoolClientId=$(get_cloudformation_stack_output" +
                            "       \"" + region + "\" " + 
                            "       \"$\{STACK_NAME}\" " +
                            "       \"" + userPoolClientId + "\" " +
                            "       || return $?)",
                            "       update_cognito_userpool_client" +
                            "       \"" + region + "\" " + 
                            "       \"$\{userPoolId}\" " + 
                            "       \"$\{userPoolClientId}\" " + 
                            "       \"$\{tmpdir}/cli-" + 
                                userPoolClientId + "-" + userPoolClientUpdateCommand + ".json\" || return $?",
                            "       ;;",
                            " esac"
                        ]
                    /]
                [/#if]
            [/#if]
        [/#list]

        [#if defaultUserPoolClientRequried && ! defaultUserPoolClientConfigured ]
                [@cfException
                    mode=listMode
                    description="A default userpool client is required"
                    context=solution
                    detail={
                        "ActionOptions" : {
                            "1" : "Add a Client to the userpool with the id default and copy any client configuration to it",
                            "2" : "Decommission the use of the legacy client and disable DefaultClient in the solution config"
                        },
                        "context" : {
                            "DefaultClient" : defaultUserPoolClientId,
                            "DefaultClientId" : getExistingReference(defaultUserPoolClientId)
                        },
                        "Configuration" : {
                            "Clients" : {
                                "default" : {
                                }
                            }
                        }
                    }
                /]
        [/#if]

        [#if deploymentSubsetRequired(USERPOOL_COMPONENT_TYPE, true) ]
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
                mfa=solution.MFA
                adminCreatesUser=solution.AdminCreatesUser
                unusedTimeout=solution.UnusedAccountTimeout
                schema=schema
                emailVerificationMessage=emailVerificationMessage
                emailVerificationSubject=emailVerificationSubject
                smsVerificationMessage=smsVerificationMessage
                smsAuthenticationMessage=smsAuthenticationMessage
                smsInviteMessage=smsInviteMessage
                emailInviteMessage=emailInviteMessage
                emailInviteSubject=emailInviteSubject
                lambdaTriggers=userPoolTriggerConfig
                autoVerify=(solution.VerifyEmail || smsVerification)?then(
                    getUserPoolAutoVerification(solution.VerifyEmail, smsVerification),
                    []
                )
                loginAliases=solution.LoginAliases
                passwordPolicy=getUserPoolPasswordPolicy( 
                        solution.PasswordPolicy.MinimumLength, 
                        solution.PasswordPolicy.Lowercase,
                        solution.PasswordPolicy.Uppsercase,
                        solution.PasswordPolicy.Numbers,
                        solution.PasswordPolicy.SpecialCharacters)
                smsConfiguration=smsConfig
            /]

            [@createIdentityPool 
                mode=listMode
                component=component
                tier=tier
                id=identityPoolId
                name=identityPoolName
                cognitoIdProviders=identityPoolProviders
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

            [#assign userPoolDomain = {
                "Domain" : userPoolHostName
            }]

            [@cfCli 
                mode=listMode
                id=userPoolDomainId
                command=userPoolDomainCommand
                content=userPoolDomain
            /]

            [#if customDomainRequired]

                [#assign userPoolCustomDomain = {
                    "Domain" : userPoolCustomDomainName,
                    "CustomDomainConfig" : {
                        "CertificateArn" : userPoolCustomDomainCertArn
                    }
                }]

                [@cfCli 
                    mode=listMode
                    id=userPoolCustomDomainId
                    command=userPoolDomainCommand
                    content=userPoolCustomDomain
                /]
            
            [/#if]

            [#assign userpoolConfig = {
                "UserPoolId": getExistingReference(userPoolId),
                "Policies": getUserPoolPasswordPolicy( 
                        solution.PasswordPolicy.MinimumLength, 
                        solution.PasswordPolicy.Lowercase,
                        solution.PasswordPolicy.Uppsercase,
                        solution.PasswordPolicy.Numbers,
                        solution.PasswordPolicy.SpecialCharacters),
                "MfaConfiguration": solution.MFA?then("ON","OFF"),
                "UserPoolTags": getCfTemplateCoreTags(
                                    userPoolName,
                                    tier,
                                    component,
                                    ""
                                    false,
                                    true),
                "AdminCreateUserConfig": getUserPoolAdminCreateUserConfig(
                                                solution.AdminCreatesUser, 
                                                solution.UnusedAccountTimeout,
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
                (solution.VerifyEmail || smsVerification),
                getUserPoolAutoVerification(solution.VerifyEmail, smsVerification)
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
        
        [#if deploymentSubsetRequired("prologue", false)]
            [@cfScript 
                mode=listMode
                content=(getExistingReference(userPoolId)?has_content)?then(
                    [
                        " # Get cli config file",
                        " split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?", 
                        " case $\{STACK_OPERATION} in",
                        "    delete)",
                        "       # Delete Userpool Domain",
                        "       info \"Removing internal userpool hosted UI Domain\"",
                        "       manage_cognito_userpool_domain" +
                        "       \"" + region + "\" " + 
                        "       \"" + getExistingReference(userPoolId) + "\" " + 
                        "       \"$\{tmpdir}/cli-" + 
                                    userPoolDomainId + "-" + userPoolDomainCommand + ".json\" \"delete\" \"internal\" || return $?"
                    ] +
                    (customDomainRequired)?then(
                        "       # Delete Userpool Domain",
                        "       info \"Removing custom userpool hosted UI Domain\"",
                        "       manage_cognito_userpool_domain" +
                        "       \"" + region + "\" " + 
                        "       \"" + getExistingReference(userPoolId) + "\" " + 
                        "       \"$\{tmpdir}/cli-" + 
                                    userPoolCustomDomainId + "-" + userPoolDomainCommand + ".json\" \"delete\" \"custom\" || return $?"
                    ) +
                    ]
                        "       ;;",
                        " esac"
                    ],
                    []
                )
            /]
        [/#if]

        [#if deploymentSubsetRequired("epilogue", false)]
            [@cfScript
                mode=listMode
                content=
                    [
                        "case $\{STACK_OPERATION} in",
                        "  create|update)"
                        "       # Adding Userpool Domain",
                        "       info \"Adding internal domain for Userpool hosted UI\"",
                        "       manage_cognito_userpool_domain" +
                        "       \"" + region + "\" " + 
                        "       \"$\{userPoolId}\" " + 
                        "       \"$\{tmpdir}/cli-" + 
                                    userPoolDomainId + "-" + userPoolDomainCommand + ".json\" \"create\" \"internal\" || return $?",
                        "       ;;",
                        " esac"
                    ] +
                    (customDomainRequired)?then(
                        [
                            "case $\{STACK_OPERATION} in",
                            "  create|update)"
                            "       # Adding Userpool Domain",
                            "       info \"Adding custom domain for Userpool hosted UI\"",
                            "       manage_cognito_userpool_domain" +
                            "       \"" + region + "\" " + 
                            "       \"$\{userPoolId}\" " + 
                            "       \"$\{tmpdir}/cli-" + 
                                        userPoolCustomDomainId + "-" + userPoolDomainCommand + ".json\" \"create\" \"custom\" || return $?",
                            "       customDomainDistribution=$(get_cognito_userpool_custom_distribution" +
                            "       \"" + region + "\" " + 
                            "       \"" + userPoolCustomDomainName + "\" " +
                            "       || return $?)"
                        ] +
                        pseudoStackOutputScript(
                            "UserPool Hosted UI Custom Domain CloudFront distribution",
                            { 
                                formatId(userPoolCustomDomainId, DNS_ATTRIBUTE_TYPE) : "$\{customDomainDistribution}"
                            },
                            "hosted-ui"
                        ) + 
                        [
                            "       ;;",
                            " esac"
                        ],
                        []
                    )+ 
                    [#-- Some Userpool Lambda triggers are not available via Cloudformation but are available via CLI --]
                    (userPoolManualTriggerConfig?has_content)?then(
                        [
                            "case $\{STACK_OPERATION} in",
                            "  create|update)"
                            "       # Add Manual Cognito Triggers",
                            "       info \"Adding Cognito Triggers that are not part of cloudformation\"",
                            "       update_cognito_userpool" +
                            "       \"" + region + "\" " + 
                            "       \"$\{userPoolId}\" " + 
                            "       \"$\{tmpdir}/cli-" + 
                                        userPoolId + "-" + userPoolUpdateCommand + ".json\" || return $?",
                            "       ;;",
                            "esac"
                        ],
                        []
                    )
            /]
        [/#if]
    [/#list]
[/#if]