[#-- Cognito User Pool --]
[#if (componentType == "userpool") && deploymentSubsetRequired("userpool", true)]
    
    [#assign userpool = component.UserPool]

    [#assign userPoolId = formatUserPoolId(tier, component)]
    [#assign userPoolName = componentShortFullName]
    [#assign dependencies = [] ]

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
        autoVerify=(userpool.verifyEmail || userpool.VerifyPhone)?then(
            getUserPoolAutoVerifcation(userpool.verifyEmail, userpool.VerifyPhone),
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
    /]

[/#if]
