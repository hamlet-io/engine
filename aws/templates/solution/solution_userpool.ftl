[#-- Cognito User Pool --]
[#if (componentType == "userpool") && deploymentSubsetRequired("userpool", true)]
    
    [#assign userpool = component.UserPool]

    [#assign userPoolId = formatUserPoolId(tier, component)]
    [#assign userPoolClientId = formatUserPoolClientId(tier, component)]
    [#assign userPoolName = componentFullName]
    [#assign userPoolClientName = formatUserPoolClientName(tier,component,userpool) ]
    [#assign dependencies = [] ]
    [#assign userPoolRoleId = formatComponentRoleId(tier, component)]
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
        id=userPoolClientId
        name=userPoolClientName
        userPoolId=userPoolId
        generateSecret=userpool.clientGenerateSecret
        tokenValidity=userpool.clientTokenValidity
        dependencies=dependencies
    /]

[/#if]
