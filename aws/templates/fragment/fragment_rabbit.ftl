[#case "rabbit"]
[#case "_rabbit"]
[#case "rabbittask"]
[#case "_rabbittask"]

    [@Attributes image="rabbitmq-autocluster" /]

    [#assign settings = _context.DefaultEnvironment]
    [#assign logLevel = (settings["LOG_LEVEL"])!"info"]

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
            "AWS_DEFAULT_REGION" : regionId
        }
    /]
    
    [@Volume "rabbit" "/var/lib/rabbitmq" "/codeontap/rabbitmq" /]
    
    [@Policy ec2AutoScaleGroupReadPermission() /]

    [#break]

