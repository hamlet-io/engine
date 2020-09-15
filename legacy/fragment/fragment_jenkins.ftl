[#case "jenkins"]
[#case "_jenkins"]

    [#assign settings = _context.DefaultEnvironment]

    [#assign jenkinsImage = settings["JENKINS_IMAGE"]!"hamletio/jenkins"]
    [@Attributes image=jenkinsImage /]

    [#assign pingInterval = (settings["AGENT_PING_INTERVAL"])!"300" ]
    [#assign pingTimeout = (settings["AGENT_PING_TIMEOUT"])!"30"]
    [#assign timeZone = (settings["TIMEZONE"])!"UTC" ]

    [#assign javaStandardOpts = [
                "-Dorg.apache.commons.jelly.tags.fmt.timeZone=${timeZone}",
                "-Duser.timezone=${timeZone}",
                "-XX:+UnlockExperimentalVMOptions",
                "-XX:+UseCGroupMemoryLimitForHeap",
                "-XX:MaxRAMFraction=2",
                "-XshowSettings:vm",
                "-Dhudson.slaves.ChannelPinger.pingIntervalSeconds=${pingInterval}",
                "-Dhudson.slaves.ChannelPinger.pingTimeoutSeconds=${pingTimeout}",
                "-Dhudson.slaves.NodeProvisioner.initialDelay=0",
                "-Dhudson.slaves.NodeProvisioner.MARGIN=50",
                "-Dhudson.slaves.NodeProvisioner.MARGIN0=0.85",
                "-Dhudson.DNSMultiCast.disabled=true",
                "-Djenkins.install.runSetupWizard=false"
    ]]

    [#assign javaExtraOpts = (settings["JAVA_EXTRA_OPTS"]!"")?split(" ")]
    [#assign javaOpts = (javaStandardOpts + javaExtraOpts)?join(" ")]

    [@Settings {
            "JAVA_OPTS" : javaOpts
        }
    /]

    [#if ! settings["ECS_ARN"]?? ]
        [@fatal
            message="Could not find ecs host for agents - add a link to the ECS Host that will run your agents"
            context=_context.Links
            detail="Add a link with the id ecs"
        /]
    [/#if]

    [#if (settings["JENKINS_JNLP_FQDN"]!"")?has_content ]
        [@Settings
            {
                "AGENT_JNLP_TUNNEL" : settings["JENKINS_JNLP_FQDN"] + ":50000"
            }
        /]
    [/#if]

    [#if (settings["JENKINS_LOCAL_FQDN"]!"")?has_content ]
        [@Settings
            {
                "AGENT_JENKINS_URL" : "http://" + settings["JENKINS_LOCAL_FQDN"] + ":8080"
            }
        /]
    [/#if]

    [@AltSettings
        {
            "JENKINS_URL" : "JENKINSLB_URL"
        }
    /]

    [#-- Validate that the appropriate settings have been provided for the container to work --]
    [#switch settings["JENKINSENV_SECURITYREALM"]!""]
        [#case "local"]
            [#if !(settings["JENKINSENV_USER"]?has_content && settings["JENKINSENV_PASS"]?has_content) ]
                [@fatal
                    message="Login Details not provided"
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
                [@fatal
                    message="Github oAuth Credentials not provided"
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
            [@fatal
                message="Security Realm Not Configured"
                context=component
                detail={
                    "JenkinsEnv" : {
                        "SecurityRealm" : "local|github"
                    }
                }
            /]
    [/#switch]

    [#-- Persistant Volume Mounts --]
    [#-- Jenkins Home --]
    [#assign JenkinsHomeFound = false ]
    [#if ((_context["Links"]["efs_jenkins_home"])!{})?has_content ]
        [#assign JenkinsHomeFound = true]
        [@Volume
            name="jenkins_home"
            containerPath="/var/jenkins_home"
            volumeLinkId="efs_jenkins_home"
        /]

    [#else]
        [#if settings["JENKINSHOMEVOLUME"]?has_content ]
            [#assign JenkinsHomeFound = true]
            [@Volume
                name="jenkinsdata"
                containerPath"/var/jenkins_home"
                hostPath=settings["JENKINSHOMEVOLUME"]
            /]
        [/#if]
    [/#if]

    [#if ! JenkinsHomeFound ]
        [@fatal
            message="Persistant Volume for Jenkins Home not found"
            detail=[
                "A persistant volume is required to host Jenkins",
                " - EFS FileSystem - add a link called efs_jenkins_home to your EFS mount from the ecs service",
                " - Host Mount - add the setting JENKINSHOMEVOLUME with the host path to map"
            ]?join(" ")
        /]
    [/#if]


    [#-- Propeties volumes provide a read only share between the jenkins server and the agents --]
    [#-- The mount can either be an efs share or a host mount which must be available to all containers --]
    [#if ((_context["Links"]["efs_properties"])!{})?has_content ]
        [@Volume
            name="codeontap_properties"
            containerPath="/var/opt/codeontap/"
            volumeLinkId="efs_properties"
        /]

        [@Volume
            name="properties"
            containerPath="/var/opt/properties/"
            volumeLinkId="efs_properties"
        /]

    [#else]

        [#if settings["CODEONTAPVOLUME"]?has_content ]
            [@Volume
                name="codeontap"
                containerPath="/var/opt/codeontap/"
                hostPath=settings["CODEONTAPVOLUME"]
            /]
        [#elseif settings["PROPERTIESVOLUME"]?has_content ]
            [@Volume
                name="codeontap"
                containerPath="/var/opt/codeontap/"
                hostPath=settings["PROPERTIESVOLUME"]
            /]
        [/#if]

        [#if settings["PROPERTIESVOLUME"]?has_content ]
            [@Volume
                name="properties"
                containerPath=(settings["PROPERTIES_DIR"])!"/var/opt/properties/"
                hostPath=settings["PROPERTIESVOLUME"]
            /]
        [/#if]

    [/#if]

    [#break]
