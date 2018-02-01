[#-- Cognito User Pool --]
[#if (componentType == "userpool") && deploymentSubsetRequired("userpool", true)]
    
    [#assign userpool = component.UserPool]

    [#assign userPoolId = formatUserPoolId(tier, component)]
    [#assign userPoolClientId = formatUserPoolClientId(tier, component)]
    [#assign userPoolIdentityPoolId = formatUserPoolIdentityPoolId(tier,component)]
    [#assign userPoolRoleId = formatComponentRoleId(tier, component)]
    [#assign userPoolIdentityUnAuthRoleId = formatDependentUserPoolIdentityUnAuthRoleId(tier, component)]
    [#assign userPoolIdentityAuthRoleId = formatDependentUserPoolIdentityAuthRoleId(tier, component)]
    [#assign userPoolIdentityRoleMappingId = formatDependentUserPoolIdentityRoleMappingId(userPoolIdentityPoolId)]
    [#assign userPoolName = componentFullName]
    [#assign userPoolIdentityPoolName = formatUserPoolIdentityPoolName(tier,component, userpool)]
    [#assign userPoolClientName = formatUserPoolClientName(tier,component,userpool) ]
    [#assign dependencies = [] ]
    [#assign smsVerification = false]

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
        [/#if]

        [#assign smsConfig = getUserPoolSMSConfiguration( getReference(userPoolRoleId, ARN_ATTRIBUTE_TYPE), userPoolName )]
        [#assign smsVerification = true]
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
        autoVerify=(userpool.verifyEmail || smsVerification)?then(
            getUserPoolAutoVerifcation(userpool.verifyEmail, smsVerification),
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

    [@createUserPoolIdentityPool 
        mode=listMode
        component=component
        tier=tier
        dependencies=dependencies
        id=userPoolIdentityPoolId
        name=userPoolIdentityPoolName
        cognitoIdProviders=cognitoIdentityPoolProvider
        allowUnauthenticatedIdentities=userpool.allowUnauthIds
    /]

    [@createRole
        mode=listMode
        id=userPoolIdentityUnAuthRoleId
        policies=[
            getPolicyDocument(
                getUserPoolUnAuthPolicy(),
                "DefaultUnAuthIdentityRole"
            )
        ]
        federatedServices="cognito-identity.amazonaws.com"
        condition={
              "StringEquals": {
                "cognito-identity.amazonaws.com:aud": getReference(userPoolIdentityPoolId)
              },
              "ForAnyValue:StringLike": {
                "cognito-identity.amazonaws.com:amr": "unauthenticated"
              }
        }
    /]

    [@createRole 
        mode=listMode
        id=userPoolIdentityAuthRoleId
        policies=[
            getPolicyDocument(
                getUserPoolAuthPolicy(),
                "DefaultAuthIdentityRole"
            )
        ]
        federatedServices="cognito-identity.amazonaws.com"
        condition={
              "StringEquals": {
                "cognito-identity.amazonaws.com:aud": getReference(userPoolIdentityPoolId)
              },
              "ForAnyValue:StringLike": {
                "cognito-identity.amazonaws.com:amr": "authenticated"
              }
        }
    /]

    [@createUserPoolIdentityPoolRoleMapping
        mode=listMode
        component=component
        tier=tier
        id=userPoolIdentityRoleMappingId
        IdentityPoolId=getReference(userPoolIdentityPoolId)
        authenticatedRoleArn=getReference(userPoolIdentityAuthRoleId, ARN_ATTRIBUTE_TYPE)
        unauthenticatedRoleArn=getReference(userPoolIdentityUnAuthRoleId, ARN_ATTRIBUTE_TYPE)
    /]

[/#if]
