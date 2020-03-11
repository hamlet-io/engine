[#ftl]
[#macro aws_userpool_cf_generationcontract_solution occurrence ]
    [@addDefaultGenerationContract subsets=["prologue", "template", "epilogue", "cli"] /]
[/#macro]

[#macro aws_userpool_cf_setup_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]
    [#local resources = occurrence.State.Resources]

    [#local userPoolId                 = resources["userpool"].Id]
    [#local userPoolName               = resources["userpool"].Name]

    [#local userPoolRoleId             = resources["role"].Id]

    [#local userPoolDomainId           = resources["domain"].Id]
    [#local userPoolHostName           = resources["domain"].Name]
    [#local customDomainRequired       = ((resources["customdomain"].Id)!"")?has_content ]
    [#if customDomainRequired ]
        [#local userPoolCustomDomainId = resources["customdomain"].Id ]
        [#local userPoolCustomDomainName = resources["customdomain"].Name ]
        [#local userPoolCustomDomainCertArn = resources["customdomain"].CertificateArn]

        [#if ! userPoolCustomDomainCertArn?has_content ]
            [@fatal
                message="ACM Certificate required in us-east-1"
                context=resources
                enabled=true
            /]
        [/#if]
    [/#if]

    [#local smsVerification = false]
    [#local userPoolTriggerConfig = {}]
    [#local smsConfig = {}]
    [#local authProviders = []]

    [#local defaultUserPoolClientRequired = false ]
    [#local defaultUserPoolClientConfigured = false ]

    [#if (resources["client"]!{})?has_content]
        [#local defaultUserPoolClientRequired = true ]
        [#local defaultUserPoolClientId = resources["client"].Id]
    [/#if]

    [#local mfaRequired = false ]

    [#if solution.MFA?is_string ]
        [#switch solution.MFA ]
            [#case "true" ]
            [#case "optional" ]
                [#local mfaRequired = true ]
                [#break]
        [/#switch]

        [#switch solution.MFA ]
            [#case "true"]
                [#local mfaConfig="ON"]
                [#break]
            [#case "false"]
                [#local mfaConfig="OFF"]
                [#break]
            [#case "optional" ]
                [#local mfaConfig="OPTIONAL"]
                [#break]
            [#default]
                [#local mfaConfig="COTFatal: Unkown MFA config option" ]
        [/#switch]

    [#else ]
        [#local mfaRequired = solution.MFA]
        [#local mfaConfig = mfaRequired?then("ON", "OFF") ]
    [/#if]

    [#local userPoolUpdateCommand = "updateUserPool" ]
    [#local userPoolClientUpdateCommand = "updateUserPoolClient" ]
    [#local userPoolDomainCommand = "setDomainUserPool" ]
    [#local userPoolAuthProviderUpdateCommand = "updateUserPoolAuthProvider" ]

    [#local emailVerificationMessage =
        getOccurrenceSettingValue(occurrence, ["UserPool", "EmailVerificationMessage"], true) ]

    [#local emailVerificationSubject =
        getOccurrenceSettingValue(occurrence, ["UserPool", "EmailVerificationSubject"], true) ]

    [#local smsVerificationMessage =
        getOccurrenceSettingValue(occurrence, ["UserPool", "SMSVerificationMessage"], true) ]

    [#local emailInviteMessage =
        getOccurrenceSettingValue(occurrence, ["UserPool", "EmailInviteMessage"], true) ]

    [#local emailInviteSubject =
        getOccurrenceSettingValue(occurrence, ["UserPool", "EmailInviteSubject"], true) ]

    [#local smsInviteMessage =
        getOccurrenceSettingValue(occurrence, ["UserPool", "SMSInviteMessage"], true) ]

    [#local smsAuthenticationMessage =
        getOccurrenceSettingValue(occurrence, ["UserPool", "SMSAuthenticationMessage"], true) ]

    [#local schema = []]
    [#list solution.Schema as key,schemaAttribute ]
        [#local schema +=  getUserPoolSchemaObject(
                            key,
                            schemaAttribute.DataType,
                            schemaAttribute.Mutable,
                            schemaAttribute.Required
        )]
    [/#list]

    [#if ((mfaRequired) || ( solution.VerifyPhone))]
        [#if ! (solution.Schema["phone_number"]!"")?has_content ]
            [@fatal
                message="Schema Attribute required: phone_number - Add Schema listed in detail"
                context=schema
                detail={
                    "phone_number" : {
                        "DataType" : "String",
                        "Mutable" : true,
                        "Required" : true
                    }
                }/]
        [/#if]

        [#local smsConfig = getUserPoolSMSConfiguration( getReference(userPoolRoleId, ARN_ATTRIBUTE_TYPE), userPoolName )]
        [#local smsVerification = true]
    [/#if]

    [#if solution.VerifyEmail || ( solution.LoginAliases.seq_contains("email"))]
        [#if ! (solution.Schema["email"]!"")?has_content ]
            [@fatal
                message="Schema Attribute required: email - Add Schema listed in detail"
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
        [#local linkTarget = getLinkTarget(occurrence, link)]

        [@debug message="Link Target" context=linkTarget enabled=false /]

        [#if !linkTarget?has_content]
            [#continue]
        [/#if]

        [#local linkTargetCore = linkTarget.Core]
        [#local linkTargetConfiguration = linkTarget.Configuration ]
        [#local linkTargetResources = linkTarget.State.Resources]
        [#local linkTargetAttributes = linkTarget.State.Attributes]

        [#switch linkTargetCore.Type]

            [#case LAMBDA_FUNCTION_COMPONENT_TYPE]

                [#-- Cognito Userpool Event Triggers --]
                [#switch link.Name?lower_case]
                    [#case "createauthchallenge"]
                        [#local userPoolTriggerConfig +=
                            attributeIfContent (
                                "CreateAuthChallenge",
                                linkTargetAttributes.ARN
                            )
                        ]
                        [#break]
                    [#case "custommessage"]
                        [#local userPoolTriggerConfig +=
                            attributeIfContent (
                                "CustomMessage",
                                linkTargetAttributes.ARN
                            )
                        ]
                        [#break]
                    [#case "defineauthchallenge"]
                        [#local userPoolTriggerConfig +=
                            attributeIfContent (
                                "DefineAuthChallenge",
                                linkTargetAttributes.ARN
                            )
                        ]
                        [#break]
                    [#case "postauthentication"]
                        [#local userPoolTriggerConfig +=
                            attributeIfContent (
                                "PostAuthentication",
                                linkTargetAttributes.ARN
                            )
                        ]
                        [#break]
                    [#case "postconfirmation"]
                        [#local userPoolTriggerConfig +=
                            attributeIfContent (
                                "PostConfirmation",
                                linkTargetAttributes.ARN
                            )
                        ]
                        [#break]
                    [#case "preauthentication"]
                        [#local userPoolTriggerConfig +=
                            attributeIfContent (
                                "PreAuthentication",
                                linkTargetAttributes.ARN
                            )
                        ]
                        [#break]
                    [#case "presignup"]
                        [#local userPoolTriggerConfig +=
                            attributeIfContent (
                                "PreSignUp",
                                linkTargetAttributes.ARN
                            )
                        ]
                        [#break]
                    [#case "verifyauthchallengeresponse"]
                        [#local userPoolTriggerConfig +=
                            attributeIfContent (
                                "VerifyAuthChallengeResponse",
                                linkTargetAttributes.ARN
                            )
                        ]
                        [#break]
                    [#case "pretokengeneration"]
                        [#local userPoolTriggerConfig +=
                            attributeIfContent (
                                "PreTokenGeneration",
                                linkTargetAttributes.ARN
                            )
                        ]
                        [#break]
                    [#case "usermigration"]
                        [#local userPoolTriggerConfig +=
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

    [#-- Initialise epilogue script with common parameters --]
    [#if deploymentSubsetRequired("epilogue", false)]
        [@addToDefaultBashScriptOutput
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

    [#if ((mfaRequired) || ( solution.VerifyPhone))]
        [#if (deploymentSubsetRequired("iam", true) || deploymentSubsetRequired("userpool", true)) &&
            isPartOfCurrentDeploymentUnit(userPoolRoleId)]

                [@createRole
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

    [#local authProviderEpilogue = []]
    [#local userPoolClientEpilogue = []]

    [#list occurrence.Occurrences![] as subOccurrence]

        [#local subCore = subOccurrence.Core ]
        [#local subSolution = subOccurrence.Configuration.Solution ]
        [#local subResources = subOccurrence.State.Resources ]

        [#if !subSolution.Enabled]
            [#continue]
        [/#if]

        [#if subCore.Type == USERPOOL_AUTHPROVIDER_COMPONENT_TYPE ]

            [#local authProviderId = subResources["authprovider"].Id ]
            [#local authProviderName = subResources["authprovider"].Name ]
            [#local authProviderEngine = subSolution.Engine]
            [#local settingsPrefix = subSolution.SettingsPrefix?upper_case?ensure_ends_with("_") ]

            [#local linkTargets = getLinkTargets(subOccurrence) ]
            [#local baselineLinks = getBaselineLinks(subOccurrence, [] )]
            [#local environment = defaultEnvironment( occurrence, linkTargets,  baselineLinks )]

            [#local authProviders += [ authProviderName ]]

            [#local attributeMappings = {} ]
            [#list subSolution.AttributeMappings as id, attributeMapping ]
                [#local localAttribute = attributeMapping.UserPoolAttribute?has_content?then(
                                            attributeMapping.UserPoolAttribute,
                                            id
                )]

                [#local attributeMappings += {
                    localAttribute : attributeMapping.ProviderAttribute
                }]
            [/#list]

            [#switch authProviderEngine ]
                [#case "SAML" ]
                    [#local samlMetdataUrl = subSolution.SAML.MetadataUrl?has_content?then(
                                                subSolution.SAML.MetadataUrl,
                                                (environment[ settingsPrefix + "SAML_METADATA_URL"])!"COTFatal: MetadataUrl not defined"
                                            )]
                    [#local samlIDPSignout = (environment[settingsPrefix + "SAML_IDP_SIGNOUT"])?has_content?then(
                                                    (environment[settingsPrefix + "SAML_IDP_SIGNOUT"]),
                                                    subSolution.SAML.EnableIDPSignOut?c
                                            )]

                    [#local providerDetails = {
                        "MetadataURL" : samlMetdataUrl,
                        "IDPSignout" : samlIDPSignout
                    }]
                    [#break]
                [#case "OIDC" ]

                    [#local oidcClientId = subSolution.OIDC.ClientId?has_content?then(
                                                subSolution.OIDC.ClientId,
                                                (environment[ settingsPrefix + "OIDC_CLIENT_ID"])!"COTFatal: ClientId not defined"
                                            )]
                    [#local oidcClientSecret = subSolution.OIDC.ClientSecret?has_content?then(
                                                subSolution.OIDC.ClientSecret,
                                                (environment[settingsPrefix + "OIDC_CLIENT_SECRET"])!"COTFatal: ClientSecret not defined"
                                            )]

                    [#local oidcScopes = subSolution.OIDC.Scopes?has_content?then(
                                                subSolution.OIDC.Scopes?join(","),
                                                (environment[settingsPrefix + "OIDC_SCOPES"])!"COTFatal: Scopes not defined"
                                            )]

                    [#local oidcAttributesMethod = subSolution.OIDC.AttributesHttpMethod?has_content?then(
                                                subSolution.OIDC.AttributesHttpMethod,
                                                (environment[settingsPrefix + "OIDC_ATTRIBUTES_HTTP_METHOD"])!"COTFatal: AttributesHttpMethod not defined"
                                            )]

                    [#local oidcIssuer = subSolution.OIDC.Issuer?has_content?then(
                                                subSolution.OIDC.Issuer,
                                                (environment[settingsPrefix + "OIDC_ISSUER"])!"COTFatal: Issuer not defined"
                                            )]

                    [#local oidcAuthorizeUrl = subSolution.OIDC.AuthorizeUrl?has_content?then(
                                                subSolution.OIDC.AuthorizeUrl,
                                                (environment[settingsPrefix + "OIDC_AUTHORIZE_URL"])!"COTFatal: AuthorizeUrl not defined"
                                            )]

                    [#local oidcTokenUrl = subSolution.OIDC.TokenUrl?has_content?then(
                                                subSolution.OIDC.TokenUrl,
                                                (environment[settingsPrefix + "OIDC_TOKEN_URL"])!"COTFatal: TokenUrl not defined"
                                            )]

                    [#local oidcAttributesUrl = subSolution.OIDC.AttributesUrl?has_content?then(
                                                subSolution.OIDC.AttributesUrl,
                                                (environment[settingsPrefix + "OIDC_ATTRIBUTES_URL"])!"COTFatal: AttributesUrl not defined"
                                            )]

                    [#local oidcJwksUrl = subSolution.OIDC.JwksUrl?has_content?then(
                                                subSolution.OIDC.JwksUrl,
                                                (environment[settingsPrefix + "OIDC_JWKS_URL"])!"COTFatal: JwksUrl not defined"
                                            )]

                    [#local providerDetails = {
                        "client_id" : oidcClientId,
                        "authorize_scopes" : oidcScopes,
                        "attributes_request_method" : oidcAttributesMethod,
                        "oidc_issuer" : oidcIssuer,
                        "authorize_url"  : oidcAuthorizeUrl,
                        "token_url" : oidcTokenUrl,
                        "attributes_url" : oidcAttributesUrl,
                        "jwks_uri" : oidcJwksUrl
                    }]
                    [#break]
            [/#switch]

            [#local updateUserPoolAuthProvider =  {
                    "AttributeMapping" : attributeMappings,
                    "ProviderDetails" : providerDetails,
                    "IdpIdentifiers" : subSolution.IDPIdentifiers
                }
            ]

            [#if deploymentSubsetRequired("cli", false)]
                [@addCliToDefaultJsonOutput
                    id=authProviderId
                    command=userPoolAuthProviderUpdateCommand
                    content=updateUserPoolAuthProvider
                /]
            [/#if]

            [#if deploymentSubsetRequired("epilogue", false)]
                [#local authProviderEpilogue +=
                    [
                        " case $\{STACK_OPERATION} in",
                        "   create|update)",
                        "       # Manage Userpool auth provider",
                        "       info \"Applying Cli level configuration to UserPool Auth Provider - Id: " + authProviderId +  "\"",
                        "       update_cognito_userpool_authprovider" +
                        "       \"" + region + "\" " +
                        "       \"$\{userPoolId}\" " +
                        "       \"" + authProviderName + "\" " +
                        "       \"" + authProviderEngine + "\" " +
                        (authProviderEngine == "OIDC" )?then(
                            "       \"" + subSolution.EncryptionScheme + "\" \"" + (oidcClientSecret!"") + "\" ",
                            "       \"\" \"\" "
                        ) +
                        "       \"$\{tmpdir}/cli-" +
                            authProviderId + "-" + userPoolAuthProviderUpdateCommand + ".json\" || return $?",
                        "       ;;",
                        " esac"
                    ]
                ]
            [/#if]
        [/#if]

        [#if subCore.Type == USERPOOL_CLIENT_COMPONENT_TYPE]

            [#if subCore.SubComponent.Id = "default" ]
                [#local defaultUserPoolClientConfigured = true]
            [/#if]

            [#local userPoolClientId           = subResources["client"].Id]
            [#local userPoolClientName         = subResources["client"].Name]

            [#local callbackUrls = []]
            [#local logoutUrls = []]
            [#local identityProviders = [ ]]

            [#list subSolution.AuthProviders as authProvider ]
                [#if authProvider?upper_case == "COGNITO" ]
                    [#local identityProviders += [ "COGNITO" ] ]
                [#else]
                    [#local linkTarget = getLinkTarget(
                                                occurrence,
                                                {
                                                    "Tier" : core.Tier.Id,
                                                    "Component" : core.Component.RawId,
                                                    "AuthProvider" : authProvider
                                                },
                                                false
                                            )]
                    [#if linkTarget?has_content && linkTarget.Configuration.Solution.Enabled  ]]
                        [#local identityProviders += [ linkTarget.State.Attributes["PROVIDER_NAME"] ]]
                    [/#if]
                [/#if]
            [/#list]

            [#list subSolution.Links?values as link]
                [#local linkTarget = getLinkTarget(subOccurrence, link)]

                [@debug message="Link Target" context=linkTarget enabled=false /]

                [#if !linkTarget?has_content]
                    [#continue]
                [/#if]

                [#local linkTargetCore = linkTarget.Core]
                [#local linkTargetConfiguration = linkTarget.Configuration ]
                [#local linkTargetResources = linkTarget.State.Resources]
                [#local linkTargetAttributes = linkTarget.State.Attributes]

                [#switch linkTargetCore.Type]
                    [#case LB_PORT_COMPONENT_TYPE]
                        [#local callbackUrls += [
                            linkTargetAttributes["AUTH_CALLBACK_URL"],
                            linkTargetAttributes["AUTH_CALLBACK_INTERNAL_URL"]
                            ]
                        ]
                        [#break]

                    [#case "external" ]
                    [#case EXTERNALSERVICE_COMPONENT_TYPE ]
                        [#if linkTargetAttributes["AUTH_CALLBACK_URL"]?has_content ]
                            [#local callbackUrls += linkTargetAttributes["AUTH_CALLBACK_URL"]?split(",") ]
                        [/#if]
                        [#if linkTargetAttributes["AUTH_SIGNOUT_URL"]?has_content ]
                            [#local logoutUrls += linkTargetAttributes["AUTH_SIGNOUT_URL"]?split(",") ]
                        [/#if]
                        [#break]

                    [#case USERPOOL_AUTHPROVIDER_COMPONENT_TYPE ]
                        [#if linkTargetConfiguration.Solution.Enabled  ]
                            [#local identityProviders += [ linkTargetAttributes["PROVIDER_NAME"] ] ]
                        [/#if]
                        [#break]
                [/#switch]
            [/#list]

            [#if deploymentSubsetRequired(USERPOOL_COMPONENT_TYPE, true) ]
                [@createUserPoolClient
                    component=core.Component
                    tier=core.Tier
                    id=userPoolClientId
                    name=userPoolClientName
                    userPoolId=userPoolId
                    generateSecret=subSolution.ClientGenerateSecret
                    tokenValidity=subSolution.ClientTokenValidity
                /]
            [/#if]

            [#if deploymentSubsetRequired("cli", false)]
                [#local updateUserPoolClient =  {
                        "CallbackURLs": callbackUrls,
                        "LogoutURLs": logoutUrls,
                        "AllowedOAuthFlows": asArray(subSolution.OAuth.Flows),
                        "AllowedOAuthScopes": asArray(subSolution.OAuth.Scopes),
                        "AllowedOAuthFlowsUserPoolClient": true,
                        "SupportedIdentityProviders" : identityProviders
                    }
                ]

                [@addCliToDefaultJsonOutput
                    id=userPoolClientId
                    command=userPoolClientUpdateCommand
                    content=updateUserPoolClient
                /]
            [/#if]

            [#if deploymentSubsetRequired("epilogue", false)]
                [#local userPoolClientEpilogue +=
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
                ]
            [/#if]
        [/#if]

    [/#list]

    [#if defaultUserPoolClientRequired && ! defaultUserPoolClientConfigured ]
            [@fatal
                message="A default userpool client is required"
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
            component=core.Component
            tier=core.Tier
            id=userPoolId
            name=userPoolName
            tags=getOccurrenceCoreTags(occurrence, userPoolName)
            mfa=mfaConfig
            adminCreatesUser=solution.AdminCreatesUser
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
                    solution.PasswordPolicy.SpecialCharacters,
                    solution.UnusedAccountTimeout)
            smsConfiguration=smsConfig
        /]

    [/#if]
    [#-- When using the cli to update a user pool, any properties that are not set in the update are reset to their default value --]
    [#-- So to use the CLI to update the lambda triggers we need to generate all of the custom configuration we use in the CF template and use this as the update --]
    [#if deploymentSubsetRequired("cli", false)]

        [#local userPoolDomain = {
            "Domain" : userPoolHostName
        }]

        [@addCliToDefaultJsonOutput
            id=userPoolDomainId
            command=userPoolDomainCommand
            content=userPoolDomain
        /]

        [#if customDomainRequired]

            [#local userPoolCustomDomain = {
                "Domain" : userPoolCustomDomainName,
                "CustomDomainConfig" : {
                    "CertificateArn" : userPoolCustomDomainCertArn
                }
            }]

            [@addCliToDefaultJsonOutput
                id=userPoolCustomDomainId
                command=userPoolDomainCommand
                content=userPoolCustomDomain
            /]

        [/#if]
    [/#if]

    [#if deploymentSubsetRequired("prologue", false)]
        [@addToDefaultBashScriptOutput
            content=(getExistingReference(userPoolId)?has_content)?then(
                [
                    " # Get cli config file",
                    " split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?",
                    " case $\{STACK_OPERATION} in",
                    "    delete)",
                    "       # Remove All Auth providers",
                    "       info \"Removing any Auth providers\"",
                    "       cleanup_cognito_userpool_authproviders" +
                    "       \"" + region + "\" " +
                    "       \"" + getExistingReference(userPoolId) + "\" " +
                    "       \"" + authProviders?join(",") + "\" " +
                    "       \"true\" || return $?",
                    "       # Delete Userpool Domain",
                    "       info \"Removing internal userpool hosted UI Domain\"",
                    "       manage_cognito_userpool_domain" +
                    "       \"" + region + "\" " +
                    "       \"" + getExistingReference(userPoolId) + "\" " +
                    "       \"$\{tmpdir}/cli-" +
                                userPoolDomainId + "-" + userPoolDomainCommand + ".json\" \"delete\" \"internal\" || return $?"
                ] +
                (customDomainRequired)?then(
                    [
                        "       # Delete Userpool Domain",
                        "       info \"Removing custom userpool hosted UI Domain\"",
                        "       manage_cognito_userpool_domain" +
                        "       \"" + region + "\" " +
                        "       \"" + getExistingReference(userPoolId) + "\" " +
                        "       \"$\{tmpdir}/cli-" +
                                    userPoolCustomDomainId + "-" + userPoolDomainCommand + ".json\" \"delete\" \"custom\" || return $?"
                    ],
                    []
                ) +
                [
                    "       ;;",
                    " esac"
                ],
                []
            )
        /]
    [/#if]

    [#if deploymentSubsetRequired("epilogue", false)]
        [@addToDefaultBashScriptOutput
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
                [#-- auth providers need to be created before userpool clients are updated --]
                (authProviderEpilogue?has_content)?then(
                    authProviderEpilogue +
                    [
                        "case $\{STACK_OPERATION} in",
                        "  create|update)"
                        "       # Remove Old Auth providers",
                        "       info \"Removing old Auth providers\"",
                        "       cleanup_cognito_userpool_authproviders" +
                        "       \"" + region + "\" " +
                        "       \"" + getExistingReference(userPoolId) + "\" " +
                        "       \"" + authProviders?join(",") + "\" " +
                        "       \"false\" || return $?",
                        "       ;;",
                        "esac"
                    ],
                    []
                ) +
                (userPoolClientEpilogue?has_content)?then(
                    userPoolClientEpilogue,
                    []
                )
        /]
    [/#if]
[/#macro]
