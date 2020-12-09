[#ftl]

[@addExtension
    id="cleanup"
    aliases=[
        "_cleanup"
    ]
    description=[
        "Docker host cleaner",
        "Removes containers and images older than the specified delay and period"
    ]
    supportedTypes=[
        ECS_SERVICE_COMPONENT_TYPE,
        ECS_TASK_COMPONENT_TYPE,
        CONTAINERSERVICE_COMPONENT_TYPE,
        CONTAINERTASK_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_cleanup_deployment_setup occurrence ]
    [@Attributes image="cleanup" /]

    [@DefaultLinkVariables enabled=false /]
    [@DefaultCoreVariables enabled=false /]
    [@DefaultEnvironmentVariables enabled=false /]
    [@DefaultBaselineVariables enabled=false /]


    [@Settings
        {
            "CLEAN_PERIOD" : (_context.DefaultEnvironment["CLEAN_PERIOD"])!"900",
            "DELAY_TIME" : (_context.DefaultEnvironment["DELAY_TIME"])!"10800"
        }
    /]

    [@Volume "dockerDaemon" "/var/run/docker.sock" "/var/run/docker.sock" /]
    [@Volume "dockerFiles" "/var/lib/docker" "/var/lib/docker" /]

[/#macro]
