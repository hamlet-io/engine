[#-- ALB --]

[#macro createTargetGroup mode tier component source destination name]
    [#local targetGroupId = formatALBTargetGroupId(tier, component, source, name)]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${targetGroupId}" : {
                "Type" : "AWS::ElasticLoadBalancingV2::TargetGroup",
                "Properties" : {
                    "HealthCheckPort" : "${(destination.HealthCheck.Port)!"traffic-port"}",
                    "HealthCheckProtocol" : "${(destination.HealthCheck.Protocol)!destination.Protocol}",
                    "HealthCheckPath" : "${destination.HealthCheck.Path}",
                    "HealthCheckIntervalSeconds" : ${destination.HealthCheck.Interval},
                    "HealthCheckTimeoutSeconds" : ${destination.HealthCheck.Timeout},
                    "HealthyThresholdCount" : ${destination.HealthCheck.HealthyThreshold},
                    "UnhealthyThresholdCount" : ${destination.HealthCheck.UnhealthyThreshold},
                    [#if (destination.HealthCheck.SuccessCodes)?? ]
                        "Matcher" : { "HttpCode" : "${destination.HealthCheck.SuccessCodes}" },
                    [/#if]
                    "Port" : ${destination.Port?c},
                    "Protocol" : "${destination.Protocol}",
                    "Tags" : [
                        { "Key" : "cot:request", "Value" : "${requestReference}" },
                        { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                        { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                        { "Key" : "cot:account", "Value" : "${accountId}" },
                        { "Key" : "cot:product", "Value" : "${productId}" },
                        { "Key" : "cot:segment", "Value" : "${segmentId}" },
                        { "Key" : "cot:environment", "Value" : "${environmentId}" },
                        { "Key" : "cot:category", "Value" : "${categoryId}" },
                        { "Key" : "cot:tier", "Value" : "${getTierId(tier)}" },
                        { "Key" : "cot:component", "Value" : "${getComponentId(component)}" },
                        { "Key" : "Name", "Value" : "${formatComponentFullName(
                                                        tier, 
                                                        component, 
                                                        source.Port?c, 
                                                        name)}" }
                    ],
                    "VpcId": "${vpc}",
                    "TargetGroupAttributes" : [
                        {
                            "Key" : "deregistration_delay.timeout_seconds",
                            "Value" : "${(destination.DeregistrationDelay)!30}"
                        }
                    ]
                }
            }
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output targetGroupId /]
            [#break]

    [/#switch]
[/#macro]
