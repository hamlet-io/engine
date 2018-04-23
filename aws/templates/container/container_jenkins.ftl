[#case "jenkins"]
    [@Attributes image="jenkins-master" /]
   
    [#assign settings = context.DefaultEnvironment]
    [@cfDebug listMode settings true /]

    [#switch settings["SECURITYREALM"]!""]
        [#case "local"]
            [#if !(settings["LOGIN_USERNAME"]?has_content && settings["LOGIN_PASSWORD"]?has_content) ]
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
            [#break]
        [#case "github"]
            [#if !(settings["GITHUB_CLIENTID"]?has_content && settings["GITHUB_SECRET"]?has_content && settings["GITHUB_ADMINISTRATORS"]?has_content) ]
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
                    }/]
            [/#if]
            [#break]
        [#default]
            [@cfException
                mode=listMode
                description="Security Realm Not Configured"
                context=component
                detail={
                    "SecurityRealm" : "local|github"
            }/]
    [/#switch]


    [@Volume "jenkinsdata" "/var/jenkins_home" "/efs/clusterstorage" /]

    [#break]