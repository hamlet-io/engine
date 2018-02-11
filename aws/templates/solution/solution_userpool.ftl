[#-- Cognito User Pool --]
[#if (componentType == "userpool") && deploymentSubsetRequired("userpool", true)]
    
    [#assign userpool = component.UserPool]

    [#assign userPoolId = formatUserPoolId(tier, component)]
    [#assign userPoolClientId = formatUserPoolClientId(tier, component)]
    [#assign userPoolRoleId = formatComponentRoleId(tier, component)]
    [#assign identityPoolId = formatIdentityPoolId(tier,component)]
    [#assign identityPoolUnAuthRoleId = formatDependentIdentityPoolUnAuthRoleId(identityPoolId)]
    [#assign identityPoolAuthRoleId = formatDependentIdentityPoolAuthRoleId(identityPoolId)]
    [#assign identityPoolRoleMappingId = formatDependentIdentityPoolRoleMappingId(identityPoolId)]
    [#assign userPoolName = formatUserPoolName(tier, component)]
    [#assign identityPoolName = formatIdentityPoolName(tier, component)]
    [#assign userPoolClientName = formatUserPoolClientName(tier, component) ]
    [#assign dependencies = [] ]
    [#assign smsVerification = false]
    [#assign schema = [] ]

    [#assign emailVerificationMessage = ""]
    [#if appSettingsObject.UserPool?has_content &&  (appSettingsObject.UserPool.EmailVerificationMessage)?has_content ]
        [#assign emailVerificationMessage = appSettingsObject.UserPool.EmailVerificationMessage ]
    [/#if]

    [#assign emailVerificationSubject = ""]
    [#if appSettingsObject.UserPool?has_content && appSettingsObject.UserPool.EmailVerificationSubject?has_content ]
        [#assign emailVerificationSubject = appSettingsObject.UserPool.EmailVerificationSubject ]
    [/#if]

    [#assign smsVerificationMessage = ""]
    [#if appSettingsObject.UserPool?has_content &&  appSettingsObject.UserPool.smsVerificationMessage?has_content ]
        [#assign emailVerificationSubject = appSettingsObject.UserPool.smsVerificationMessage ]
    [/#if]


    [#if (userpool.MFA?has_content && userpool.MFA) || (userpool.VerifyPhone?has_content && userpool.VerifyPhone)]
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

    [#if userpool.verifyEmail || ( userpool.loginAliases?has_content && userpool.loginAliases.seq_contains("email") ) ]
            [#assign emailSchema = getUserPoolSchemaObject( 
                                        "email",
                                        "String",
                                        true,
                                        true)]
            [#assign schema = schema +  [ emailSchema ]]
    [/#if]

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
        mfa=userpool.MFA
        adminCreatesUser=userpool.adminCreatesUser
        unusedTimeout=userpool.unusedAccountTimeout
        schema=schema
        emailVerificationMessage=emailVerificationMessage
        emailVerificationSubject=emailVerificationSubject
        smsVerificationMessage=smsVerificationMessage
        autoVerify=(userpool.verifyEmail || smsVerification)?then(
            getUserPoolAutoVerification(userpool.verifyEmail, smsVerification),
            []
        )
        loginAliases=((userpool.loginAliases)?has_content)?then(
            [userpool.loginAliases],
            [])
        passwordPolicy=((userpool.passwordPolicy)?has_content)?then(
            getUserPoolPasswordPolicy( userpool.passwordPolicy.minimumLength, 
                                        userpool.passwordPolicy.lowercase,
                                        userpool.passwordPolicy.uppsercase,
                                        userpool.passwordPolicy.numbers,
                                        userpool.passwordPolicy.specialCharacters),
            {})
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
        generateSecret=userpool.clientGenerateSecret
        tokenValidity=userpool.clientTokenValidity

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
        allowUnauthenticatedIdentities=userpool.allowUnauthIds
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
