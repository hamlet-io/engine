[#case "jenkins"]
    [@Attributes image="jenkins-master" /]
   
    [#assign settings = context.DefaultEnvironment]

    [@Policy ecsTaskAllPermission() /]

    [@Settings {
            "ECS_ARN" :  getExistingReference(ecsId)
        }
    /]

    [#-- Validate that the appropriate settings have been provided for the container to work --]
    [#switch settings["JENKINSENV_SECURITYREALM"]!""]
        [#case "local"]
            [#if !(settings["JENKINSENV_USER"]?has_content && settings["JENKINSENV_PASS"]?has_content) ]
                [@cfException
                    mode=listMode
                    description="Login Details not provided"
                    context=component
                    detail={
                        "JenkinsEnv" : {
                            "User" : "",
                            "Pass" : ""
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
                        "GithubAuth" : {
                            "ClientId" : "",
                            "Secret" : "",
                            "Admin" : ""
                        }
                    }
                /]
            [/#if]
            [#break]
        [#default]
            [@cfException
                mode=listMode
                description="Security Realm Not Configured"
                context=component
                detail={ 
                    "JenkinsEnv" : {
                        "SecurityRealm" : "local|github"
                    }
                }
            /]
    [/#switch]

    [#if settings["JENKINSHOMEVOLUME"]?has_content ]
        [@Volume "jenkinsdata" "/var/jenkins_home" settings["JENKINSHOMEVOLUME"] /]
    [/#if]   

    [#if settings["CODEONTAPVOLUME"]?has_content ]
        [@Volume "codeontap" "/var/opt/codeontap/" settings["CODEONTAPVOLUME"] /]
    [/#if]  

    [#break]