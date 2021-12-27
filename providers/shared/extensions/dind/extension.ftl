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

    [#local defaultEnv = _context.DefaultEnvironment]

    [@Hostname hostname=(_context.Name)?replace("_", "") /]

    [#local dockerStageDir = defaultEnv["DOCKER_STAGE_DIR"]!"/home/jenkins"  ]
    [#local dockerStageSize = defaultEnv["DOCKER_STAGE_SIZE_GB"]!"20"        ]
    [#local dockerStagePersist = (defaultEnv["DOCKER_STAGE_PERSIST"]?boolean)!false ]
    [#local dockerLibSize = defaultEnv["DOCKER_LIB_VOLUME_SIZE"]!"20"         ]
    [#local dindTLSVerify = defaultEnv["DIND_DOCKER_TLS_VERIFY"]!"true"      ]

    [#if ((_context.Container.Image.Source)!"") != "containerregistry" ]
        [@Attributes
            image="docker"
            version="dind"
        /]
    [/#if]

    [#if dindTLSVerify?boolean ]
        [@Settings
            {
                "DOCKER_TLS_CERTDIR" : "/docker/certs"
            }
        /]

        [@Volume
            name="dind_certs_client"
            containerPath="/docker/certs/client"
        /]
    [/#if]

    [@Settings ["BUILD_REFERENCE"] /]

    [@Volume
        name="dockerStage"
        containerPath=dockerStageDir
        volumeEngine="ebs"
        scope=dockerStagePersist?then(
                    "shared",
                    "task"
        )
        driverOpts={
            "volumetype": "gp2",
            "size": dockerStageSize
        }
    /]

    [@Volume
        name="dind_lib"
        containerPath="/var/lib/docker"
        volumeEngine="ebs"
        scope="task"
        scope=dockerStagePersist?then(
            "shared",
            "task"
        )
        driverOpts={
            "volumetype": "gp2",
            "size": dockerLibSize
        }
    /]

[/#macro]
