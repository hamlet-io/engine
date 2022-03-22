[#ftl]

[@addExtension
    id="dind"
    aliases=[
        "_dind"
    ]
    description=[
        "Docker in Docker container",
        "Provides access to a docker in docker container configured with its own dedicated storage volumes provisioned on demand",
        "Generates a TLS certificate which can be shared with other containers as part of a task or service"
    ]
    supportedTypes=[
        ECS_SERVICE_COMPONENT_TYPE,
        ECS_TASK_COMPONENT_TYPE,
        CONTAINERSERVICE_COMPONENT_TYPE,
        CONTAINERTASK_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_dind_deployment_setup occurrence ]

    [@DefaultLinkVariables enabled=false /]
    [@DefaultCoreVariables enabled=false /]
    [@DefaultEnvironmentVariables enabled=false /]
    [@DefaultBaselineVariables enabled=false /]
    [@DefaultComponentVariables enabled=false /]

    [@Hostname hostname=(_context.Name)?replace("_", "") /]

    [#local dockerStageDir = _context.DefaultEnvironment["DOCKER_STAGE_DIR"]!"/home/jenkins"  ]

    [@Settings
        {
            "DOCKER_TLS_CERTDIR" : "/docker/certs"
        }
    /]

    [@Volume
        name="dind_certs_client"
        containerPath="/docker/certs/client"
    /]

    [@Volume
        name="dockerStage"
        containerPath=dockerStageDir
    /]

    [@Volume
        name="dind_lib"
        containerPath="/var/lib/docker"
    /]
[/#macro]
