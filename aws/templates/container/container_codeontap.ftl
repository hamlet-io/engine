[#case "codeontap"]
    [#assign settings = context.DefaultEnvironment]

    [@Attributes image="gen3-jenkins-slave" /]
    
    [@DefaultLinkVariables enabled=false /]
    [@DefaultCoreVariables enabled=false /]
    [@DefaultEnvironmentVariables enabled=false /]

    [@Settings {
        "JAVA_OPTS" : "-Dhudson.remoting.Launcher.pingIntervalSec=1200",
        "ENABLE_DOCKER" : "true",
        "AWS_AUTOMATION_USER" : "ROLE"
    }/]

    [#-- Validate that the appropriate settings have been provided for the container to work --]
    [#if settings["CODEONTAPVOLUME"]?has_content ]
        [@Volume "codeontap" "/var/opt/codeontap/" settings["CODEONTAPVOLUME"] /]
    [/#if]  

    [#if settings["AWSPROFILEVOLUME"]?has_content ]
        [#assign awsProfilePath = "/var/opt/awsprofile/" ]

        [@Volume "awsprofile" awsProfilePath settings["AWSPROFILEVOLUME"] /]
        [@Variable "AWS_CONFIG_FILE" awsProfilePath + "config" /]
    [/#if]

    [#if settings["AWS_AUTOMATION_POLICIES"]?has_content ]
        [@ManagedPolicy settings["AWS_AUTOMATION_POLICIES"]?split(",") /]
    [#else]
        [@Policy
            globalAdministratorAccess()
        /]
    [/#if]

    [#break]