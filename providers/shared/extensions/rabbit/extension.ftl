[#ftl]

[@addExtension
    id="rabbit"
    aliases=[
        "_rabbit"
    ]
    description=[
        "Basic rabbitmq deployment with AWS ASG autoscaling"
    ]
    supportedTypes=[
        ECS_SERVICE_COMPONENT_TYPE,
        ECS_TASK_COMPONENT_TYPE,
        CONTAINERSERVICE_COMPONENT_TYPE,
        CONTAINERTASK_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_rabbit_deployment_setup occurrence ]

    [@Attributes image="rabbitmq-autocluster" /]

    [#local settings = _context.DefaultEnvironment]
    [#local logLevel = (settings["LOG_LEVEL"])!"info"]

    [@DefaultLinkVariables enabled=false /]
    [@DefaultCoreVariables enabled=false /]
    [@DefaultEnvironmentVariables enabled=false /]

    [@Variables
        {
            "AUTOCLUSTER_TYPE" : "aws",
            "AUTOCLUSTER_CLEANUP" : "true",
            "AUTOCLUSTER_LOG_LEVEL" : logLevel,
            "CLEANUP_WARN_ONLY" : "false",
            "AWS_AUTOSCALING" : "true",
            "AWS_DEFAULT_REGION" : getRegion()
        }
    /]

    [@Volume "rabbit" "/var/lib/rabbitmq" "/codeontap/rabbitmq" /]

    [@Policy ec2AutoScaleGroupReadPermission() /]

[/#macro]
