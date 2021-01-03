[#ftl]

[@addExtension
    id="redirector"
    aliases=[
        "_redirector"
    ]
    description=[
        "HTTP -> HTTPS redirection service"
    ]
    supportedTypes=[
        ECS_SERVICE_COMPONENT_TYPE,
        ECS_TASK_COMPONENT_TYPE,
        CONTAINERSERVICE_COMPONENT_TYPE,
        CONTAINERTASK_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_redirector_deployment_setup occurrence ]

    [@DefaultLinkVariables enabled=false /]
    [@DefaultCoreVariables enabled=false /]
    [@DefaultEnvironmentVariables enabled=false /]

    [@Attributes image="redirector" /]

[/#macro]
