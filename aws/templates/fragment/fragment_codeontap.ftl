[#case "codeontap"]
[#case "_codeontap"]

    [#assign settings = _context.DefaultEnvironment]

    [#assign dockerStageDir = settings["DOCKER_STAGE_DIR"]!"/tmp/docker-build" ]
    [#assign dockerHostDaemon = settings["DOCKER_HOST_DAEMON"]!"/var/run/docker.sock"]
    [#assign jenkinsAgentImage = settings["DOCKER_AGENT_IMAGE"]!"gen3"]

    [@Attributes image=jenkinsAgentImage /]
    
    [@DefaultLinkVariables enabled=false /]
    [@DefaultCoreVariables enabled=false /]
    [@DefaultEnvironmentVariables enabled=false /]

    [@Settings {
        "AWS_AUTOMATION_USER" : "ROLE",
        "DOCKER_STAGE_DIR" : dockerStageDir
    }/]

    [@Volume 
        name="dockerDaemon" 
        containerPath="/var/run/docker.sock" 
        hostPath=dockerHostDaemon  
    /]
    [@Volume 
        name="dockerStage" 
        containerPath=dockerStageDir 
        hostPath=dockerStageDir 
    /]

    [#-- Validate that the appropriate settings have been provided for the container to work --]
    [#if settings["CODEONTAPVOLUME"]?has_content ]
        [@Volume 
            name="codeontap" 
            containerPath="/var/opt/codeontap/" 
            hostPath=settings["CODEONTAPVOLUME"] 
            readOnly=true     
        /]
    [/#if]  

    [#if settings["AWS_AUTOMATION_POLICIES"]?has_content ]
        [@ManagedPolicy settings["AWS_AUTOMATION_POLICIES"]?split(",") /]
    [/#if]

    [#break]

[#case "_jenkinsecs" ] 
    [#assign settings = _context.DefaultEnvironment]

    [#-- The docker stage dir is used to provide a staging location for docker in docker based builds which use the host docker instance --]
    [#assign dockerStageDirs = 
            (settings["DOCKER_STAGE_DIR"])?has_content?then(
                    asArray(settings["DOCKER_STAGE_DIR"]),
                    settings["DOCKER_STAGE_DIRS"]?has_content?then(
                        asArray( (settings["DOCKER_STAGE_DIRS"]?split(",") )),
                        [ "/tmp/docker-build" ]
                    )
            )]
    
    [#list dockerStageDirs as dockerStageDir]
        [@Directory
            path=dockerStageDir
            mode="775"
            owner="1000"
            group="1000"
        /]
    [/#list]
    [#break]
