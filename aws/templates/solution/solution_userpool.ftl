[#-- Cognito User Pool --]
[#if (componentType == "userpool") && deploymentSubsetRequired("userpool", true)]
    
    [#assign userpool = component.UserPool]

    [#assign userPoolId = formatUserPoolId(tier, component)]
    [#assign userPoolName = componentFullName]
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
                            snsPublishPermission() 
                        )
                    ]
            /]
        [/#if]

        [#assign smsConfig = getUserPoolSMSConfiguration( getReference(userPoolRoleId), userPoolName )]
        [#assign smsVerification = true]
    [/#if]

    [@createUserPool 
        mode=listMode
        component=component
        tier=tier
        id=userPoolId
        name=userPoolName
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

[/#if]
