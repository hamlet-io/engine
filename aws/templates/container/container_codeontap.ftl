[#case "codeontap"]
    [#assign settings = context.DefaultEnvironment]

    [@Attributes image="gen3-jenkins-slave" /]
    
    [@DefaultLinkVariables enabled=false /]
    [@DefaultCoreVariables enabled=false /]
    [@DefaultEnvironmentVariables enabled=false /]

    [@Settings {
        "AWS_AUTOMATION_USER" : "ROLE"
    }/]
    
    [#assign dockerStageDir = settings["DOCKER_STAGE_DIR"]!"/tmp" ]

    [@Volume "dockerDaemon" "/var/run/docker.sock" settings["DOCKER_HOST_DAEMON"]!"/var/run/docker.sock" /]
    [@Volume "dockerStage" dockerStageDir dockerStageDir /]

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