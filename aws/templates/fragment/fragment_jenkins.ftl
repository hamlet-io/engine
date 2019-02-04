[#case "jenkins"]
[#case "_jenkins"]

    [@Attributes image="jenkins-master" /]
   
    [#assign settings = _context.DefaultEnvironment]

    [#assign pingInterval = (settings["AGENT_PING_INTERVAL"])!"300" ]
    [#assign pingTimeout = (settings["AGENT_PING_TIMEOUT"])!"30"]
    [#assign timeZone = (settings["TIMEZONE"])!"UTC" ]
    [#assign maxMemory = (container.MemoryReservation * 0.9)?round?c ]
    [#assign intialHeapSize = (container.MemoryReservation * 0.5)?round?c ]

    [#assign javaStandardOpts = [ 
                "-Dhudson.DNSMultiCast.disabled=true",
                "-Djenkins.install.runSetupWizard=false",
                "-Dorg.apache.commons.jelly.tags.fmt.timeZone=${timeZone}",
                "-Duser.timezone=${timeZone}",
                "-Xmx${maxMemory}M",
                "-Xms${intialHeapSize}M",
                "-Dhudson.slaves.ChannelPinger.pingIntervalSeconds=${pingInterval}",
                "-Dhudson.slaves.ChannelPinger.pingTimeoutSeconds=${pingTimeout}",
                "-Dhudson.slaves.NodeProvisioner.initialDelay=0",
                "-Dhudson.slaves.NodeProvisioner.MARGIN=50",
                "-Dhudson.slaves.NodeProvisioner.MARGIN0=0.85"
    ]]

    [#assign javaExtraOpts = (settings["JAVA_EXTRA_OPTS"]!"")?split(" ")]
    [#assign javaOpts = (javaStandardOpts + javaExtraOpts)?join(" ")]

    [@Settings {
            "ECS_ARN" :  getExistingReference(ecsId),
            "JAVA_OPTS" : javaOpts
        }
    /]

    [@AltSettings 
        {
            "JENKINS_URL" : "JENKINSLB_URL"
        }/]

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

        [#case "custom"]
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