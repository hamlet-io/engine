[#case "rabbit"]
[#case "rabbittask"]
    [#switch containerListMode]
        [#case "definition"]
            [@containerBasicAttributes
                containerName
                "rabbitmq-autocluster" + dockerTag
            /]
            [#break]

        [#case "environmentCount"]
        [#case "environment"]
            [@standardEnvironmentVariables
                containerListTarget containerListMode/]
            [@environmentVariable
                "AUTOCLUSTER_TYPE" "aws"
                containerListTarget containerListMode/]
            [@environmentVariable 
                "AUTOCLUSTER_CLEANUP" "true"
                containerListTarget containerListMode/]
            [@environmentVariable
                "AUTOCLUSTER_LOG_LEVEL" "debug"
                containerListTarget containerListMode/]
            [@environmentVariable
                "CLEANUP_WARN_ONLY" "false"
                containerListTarget containerListMode/]
            [@environmentVariable
                "AWS_AUTOSCALING" "true"
                containerListTarget containerListMode/]
            [@environmentVariable 
                "AWS_DEFAULT_REGION" "${regionId}"
                containerListTarget containerListMode/]
            [#break]

        [#case "volumeCount"]
        [#case "volumes"]
        [#case "mountPointCount"]
        [#case "mountPoints"]
            [@containerVolume
                "rabbit"
                "/var/lib/rabbitmq"
                "/codeontap/rabbitmq" /]
            [#break]

        [#case "policyCount"]
        [#case "policy"]
            [@policyHeader
                containerListPolicyName
                containerListPolicyId
                containerListRole/]
            [@autoScaleGroupReadStatement /]
            [@policyFooter /]
            [#break]

    [/#switch]
    [#break]

