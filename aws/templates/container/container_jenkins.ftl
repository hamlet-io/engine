[#case "jenkins"]
    [@Attributes image="jenkins-master" /]
   
    [#assign settings = context.DefaultEnvironment]

    [@Settings {
            "ECS_ARN" :  getExistingReference(ecsId)
        }
    /]

    [#-- Validate that the appropriate settings have been provided for the container to work --]
    [#switch settings["JENKINS_SECURITYREALM"]!""]
        [#case "local"]
            [#if !(settings["JENKINS_USER"]?has_content && settings["JENKINS_PASS"]?has_content) ]
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
            [#if !(settings["GITHUBAUTH_CLIENTID"]?has_content && settings["GITHUBAUTH_SECRET"]?has_content && settings["GITHUBAUTH_ADMIN"]?has_content) ]
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

    [#if settings["JENKINSHOMEVOLUME"]?has_content ]
        [@Volume "jenkinsdata" "/var/jenkins_home" settings["JENKINSHOMEVOLUME"] /]
    [/#if]   

    [#if settings["CODEONTAPVOLUME"]?has_content ]
        [@Volume "codeontap" "/var/opt/codeontap/" settings["CODEONTAPVOLUME"] /]
    [/#if]  

    [#break]