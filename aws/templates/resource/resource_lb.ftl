[#-- ALB --]

[#assign LB_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        DNS_ATTRIBUTE_TYPE : {
            "Attribute" : "DNSName"
        }
    }
]

[#assign ALB_LISTENER_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]

[#assign ALB_LISTENER_RULE_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]

[#assign ALB_TARGET_GROUP_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        NAME_ATTRIBUTE_TYPE : {
            "Attribute" : "TargetGroupFullName"
        }
    }
]

[#assign outputMappings +=
    {
        AWS_LB_RESOURCE_TYPE : LB_OUTPUT_MAPPINGS,
        AWS_ALB_RESOURCE_TYPE : LB_OUTPUT_MAPPINGS,
        AWS_ALB_LISTENER_RESOURCE_TYPE : ALB_LISTENER_OUTPUT_MAPPINGS,
        AWS_ALB_LISTENER_RULE_RESOURCE_TYPE : ALB_LISTENER_RULE_OUTPUT_MAPPINGS,
        AWS_ALB_TARGET_GROUP_RESOURCE_TYPE : ALB_TARGET_GROUP_OUTPUT_MAPPINGS
    }
]

[#macro createALB mode id name shortName tier component securityGroups type logs=false bucket=""]
    [@cfResource
        mode=mode
        id=id
        type="AWS::ElasticLoadBalancingV2::LoadBalancer"
        properties=
            {
                "Subnets" : getSubnets(tier),
                "Scheme" : (tier.Network.RouteTable == "external")?then("internet-facing","internal"),
                "Name" : shortName
            } +
            attributeIfTrue(
                "Type",
                type != "application",
                type
            ) +
            attributeIfTrue(
                "LoadBalancerAttributes",
                logs && type == "application",
                [
                    {
                        "Key" : "access_logs.s3.enabled",
                        "Value" : true
                    },
                    {
                        "Key" : "access_logs.s3.bucket",
                        "Value" : bucket
                    },
                    {
                        "Key" : "access_logs.s3.prefix",
                        "Value" : ""
                    }
            ]) + 
            attributeIfTrue(
                "SecurityGroups",
                type == "application",
                getReferences(securityGroups)
            )
            
        tags=getCfTemplateCoreTags(name, tier, component)
        outputs=LB_OUTPUT_MAPPINGS
    /]
[/#macro]

[#macro createALBListener mode id port albId defaultTargetGroupId certificateId=""]

    [@cfResource
        mode=mode
        id=id
        type="AWS::ElasticLoadBalancingV2::Listener"
        properties=
            {
                "DefaultActions" : [
                    {
                      "TargetGroupArn" : getReference(defaultTargetGroupId),
                      "Type" : "forward"
                    }
                ],
                "LoadBalancerArn" : getReference(albId),
                "Port" : port.Port,
                "Protocol" : port.Protocol
            } +
            valueIfTrue(
                {
                    "Certificates" : [
                        {
                            "CertificateArn" : getReference(certificateId, ARN_ATTRIBUTE_TYPE, regionId)
                        }
                    ],
                    "SslPolicy" : "ELBSecurityPolicy-TLS-1-2-2017-01"
                },
                port.Certificate!false)
        outputs=ALB_LISTENER_OUTPUT_MAPPINGS
    /]
[/#macro]

[#macro createTargetGroup mode id name tier component destination targetType=""]
    [@cfResource
        mode=mode
        id=id
        type="AWS::ElasticLoadBalancingV2::TargetGroup"
        properties=
            {
                "HealthCheckPort" : (destination.HealthCheck.Port)!"traffic-port",
                "HealthCheckProtocol" : (destination.HealthCheck.Protocol)!destination.Protocol,
                "HealthCheckIntervalSeconds" : destination.HealthCheck.Interval,
                "HealthCheckTimeoutSeconds" : destination.HealthCheck.Timeout,
                "HealthyThresholdCount" : destination.HealthCheck.HealthyThreshold,
                "UnhealthyThresholdCount" : destination.HealthCheck.UnhealthyThreshold,
                "Port" : destination.Port,
                "Protocol" : destination.Protocol,
                "VpcId": vpc,
                "TargetGroupAttributes" : [
                    {
                        "Key" : "deregistration_delay.timeout_seconds",
                        "Value" : (destination.DeregistrationDelay)!30
                    }
                ]
            } +
            valueIfContent(
                {
                    "Matcher" : { "HttpCode" : (destination.HealthCheck.SuccessCodes)!"" }
                },
                (destination.HealthCheck.SuccessCodes)!"") + 
            valueIfTrue(
                {
                    "TargetType" : targetType
                },
                targetType == "ip"
            ) + 
            valueIfContent(
                {
                    "HealthCheckPath" : (destination.HealthCheck.Path)!""
                },
                (destination.HealthCheck.Path)!""
            )
        tags= getCfTemplateCoreTags(name, tier, component)
        outputs=ALB_TARGET_GROUP_OUTPUT_MAPPINGS
    /]
[/#macro]

[#function getListenerRuleForwardAction targetGroupId]
    [#return
        [
            {
                "Type": "forward",
                "TargetGroupArn": getReference(targetGroupId)
            }
        ]
    ]
[/#function]

[#function getListenerRulePathCondition paths]
    [#return
        [
            {
                "Field": "path-pattern",
                "Values": asArray(paths)
            }
        ]
    ]
[/#function]

[#macro createListenerRule mode id listenerId actions=[] conditions=[] priority=100 dependencies=""]
    [@cfResource
        mode=mode
        id=id
        type="AWS::ElasticLoadBalancingV2::ListenerRule"
        properties=
            {
                "Priority" : priority,
                "Actions" : actions,
                "Conditions": conditions,
                "ListenerArn" : getReference(listenerId, ARN_ATTRIBUTE_TYPE)
            }
        outputs=ALB_LISTENER_RULE_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]

[#macro createClassicLB mode id name shortName tier component listeners healthCheck securityGroups logs=false bucket="" dependencies="" ]
        [@cfResource
        mode=listMode
        id=id
        type="AWS::ElasticLoadBalancing::LoadBalancer"
        properties=
            {
                "Listeners" : listeners,
                "HealthCheck" : healthCheck,
                "Scheme" :
                    (tier.Network.RouteTable == "external")?then(
                        "internet-facing",
                        "internal"
                    ),
                "SecurityGroups": getReferences(securityGroups),
                "LoadBalancerName" : shortName
            } +
            multiAZ?then(
                {
                    "Subnets" : getSubnets(tier),
                    "CrossZone" : true
                },
                {
                    "Subnets" : [ getSubnets(tier)[0] ]
                }
            ) +
            (logs)?then(
                {
                    "AccessLoggingPolicy" : {
                        "EmitInterval" : 5,
                        "Enabled" : true,
                        "S3BucketName" : bucket
                    }
                },
                {}
            )
        tags=
            getCfTemplateCoreTags(
                name,
                tier,
                component)
        outputs=LB_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]