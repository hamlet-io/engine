[#-- Cognito User Pool --]
[#if (componentType == "userpool") && deploymentSubsetRequired("userpool", true)]
    
    [#assign userpool = component.UserPool]

    [#list getOccurrences(component, deploymentUnit) as occurrence]

        [#assign userPoolId = formatUserPoolId(tier, component)]
        [#assign userPoolName = componentShortFullName]
        [#assign dependencies = [] ]

        [@createUserPool 
            mode=listMode
            component=component
            tier=tier

            Id=userPoolId
            name=userPoolName
            dependencies=dependencies
            mfa=occurrence.MFA
            adminCreatesUser=occurrence.adminCreatesUser
            unusedTimeout=occurrence.unusedAccountTimeout
            verifyEmail=occurrence.verifyEmail
            verifyPhone=occurrence.verifyPhone
            loginAliases=(occurrence.loginAliases.Configured && (occurrence.loginAliases)?has_content)?then(
                occurrence.loginAliases,
                []
            )
            passwordPolicy=(occurrence.passwordPolicy.Configured && (occurrence.passwordPolicy)?has_content? then(
                getUserPoolPasswordPolicy(  occurrence.passwordPolicy.MinimumLength, 
                                            occurrence.passwordPolicy.Lowercase,
                                            occurrence.passwordPolicy.Uppsercase,
                                            occurrence.passwordPolicy.Numbers,
                                            occurrence.passwordPolicy,SpecialCharacters 
                                            )
            ))
        ]

    [/#list]


[/#if]
