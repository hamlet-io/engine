[#case "rabbit"]
[#case "_rabbit"]
[#case "rabbittask"]
[#case "_rabbittask"]

    [@Attributes image="rabbitmq-autocluster" /]

    [@Variables
        {
            "AUTOCLUSTER_TYPE" : "aws",
            "AUTOCLUSTER_CLEANUP" : "true",
            "AUTOCLUSTER_LOG_LEVEL" : "debug",
            "CLEANUP_WARN_ONLY" : "false",
            "AWS_AUTOSCALING" : "true",
            "AWS_DEFAULT_REGION" : regionId
        }
    /]
    
    [@Volume "rabbit" "/var/lib/rabbitmq" "/codeontap/rabbitmq" /]
    
    [@Policy ec2AutoScaleGroupReadPermission() /]

    [#break]

