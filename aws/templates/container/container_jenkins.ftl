[#case "jenkins"]
    [@Attributes image="jenkins-master" /]
   
    [#assign credentials = credentialsObject]

    [#if (credentials.SecurityRealm)?has_content ]

        [#if (credentials.SecurityRealm) == "local" ]
            [#if (credentials.Login.Username)?has_content || (credentials.Login.Password)?has_content ]
                [@Variables
                    {
                        "JENKINS_USER"          : credentials.Login.Username,
                        "JENKINS_PASS"          : credentials.Login.Password,
                        "JENKINS_SECURITYREALM" : credentials.SecurityRealm
                    }
                /]
            [#else]
                [@cfException
                    mode=listMode
                    description="Login Details not provided"
                    context=component
                    detail={
                        "Login" : {
                            "Username" : "",
                            "Password" : ""
                        }
                    }
                /]
            [/#if]
        [/#if]

        [#if (credentials.SecurityRealm) == "github"]
            [#if (credentials.GitHub.ClientId)?has_content && (credentials.GitHub.Secret)?has_content && (credentials.GitHub.Administrators)?has_content]
                [@Variables
                    {
                        "JENKINS_SECURITYREALM" : credentials.SecurityRealm,
                        "GITHUBAUTH_CLIENTID"   : credentials.GitHub.ClientId,
                        "GITHUBAUTH_SECRET"     : credentials.GitHub.Secret,
                        "GITHUBAUTH_ADMIN"      : credentials.GitHub.Administrators
                    }
                /]

            [#else]
                [@cfException
                    mode=listMode
                    description="Github oAuth Credentials not provided"
                    context=component
                    detail={
                        "Github" : {
                            "ClientId" : "",
                            "Secret" : "",
                            "Administrators" : ""
                        }
                    }
                /]
            [/#if]

        [/#if]        
        
    [#else]
        [@cfException
            mode=listMode
            description="Security Realm Not Configured"
            context=component
            detail={
                "SecurityRealm" : "local|github"
            }
        /]
    [/#if]
    [@Volume "jenkinsdata" "/var/jenkins_home" "/efs/clusterstorage" /]

    [#break]