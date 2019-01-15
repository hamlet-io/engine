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

[#macro createALB mode id name shortName tier component securityGroups type idleTimeout logs=false bucket=""]

    [#assign loadBalancerAttributes = 
        ( type == "application" )?then(
            [
                {
                    "Key" : "idle_timeout.timeout_seconds",
                    "Value" : idleTimeout
                }
            ],
            []
        ) +
        (logs && type == "application")?then(
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
            ],
            []
        )
    ]

    [@cfResource
        mode=mode
        id=id
        type="AWS::ElasticLoadBalancingV2::LoadBalancer"
        properties=
            {
                "Subnets" : getSubnets(tier),
                "Scheme" : (tier.Network.RouteTable == "external")?then("internet-facing","internal"),
                "Name" : shortName,
                "LoadBalancerAttributes" : loadBalancerAttributes
            } +
            attributeIfTrue(
                "Type",
                type != "application",
                type
            ) + 
            attributeIfTrue(
                "SecurityGroups",
                type == "application",
                getReferences(securityGroups)
            )
            
        tags=getCfTemplateCoreTags(name, tier, component)
        outputs=LB_OUTPUT_MAPPINGS
    /]
[/#macro]

[#macro createALBListener mode id port albId defaultTargetGroupId certificateId="" sslPolicy="" ]

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
                    "SslPolicy" : sslPolicy
                },
                port.Certificate!false)
        outputs=ALB_LISTENER_OUTPUT_MAPPINGS
    /]
[/#macro]

[#macro createTargetGroup mode id name tier component destination attributes targetType=""]

    [#local healthCheckProtocol = (destination.HealthCheck.Protocol)!destination.Protocol]

    [#local targetGroupAttributes = [] ]
    [#list attributes as key,value ]
        [#local targetGroupAttributes += 
            [
                {
                    "Key" : key,
                    "Value" : value
                }
            ]]
    [/#list]

    [@cfResource
        mode=mode
        id=id
        type="AWS::ElasticLoadBalancingV2::TargetGroup"
        properties=
            {
                "HealthCheckPort" : (destination.HealthCheck.Port)!"traffic-port",
                "HealthCheckProtocol" : healthCheckProtocol,
                "HealthCheckIntervalSeconds" : destination.HealthCheck.Interval,
                "HealthyThresholdCount" : destination.HealthCheck.HealthyThreshold,
                "Port" : destination.Port,
                "Protocol" : destination.Protocol,
                "VpcId": vpc,
                "TargetGroupAttributes" : targetGroupAttributes
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
            ) + 
            (healthCheckProtocol != "TCP")?then(
                {
                    "HealthCheckTimeoutSeconds" : destination.HealthCheck.Timeout,
                    "UnhealthyThresholdCount" : destination.HealthCheck.UnhealthyThreshold
                },
                {
                    "UnhealthyThresholdCount" : destination.HealthCheck.HealthyThreshold
                }
                
            )
        tags= getCfTemplateCoreTags(name, tier, component)
        outputs=ALB_TARGET_GROUP_OUTPUT_MAPPINGS
    /]
[/#macro]

[#function getListenerRuleForwardAction targetGroupId order=""]
    [#return
        [
            {
                "Type": "forward",
                "TargetGroupArn": getReference(targetGroupId, ARN_ATTRIBUTE_TYPE)
            } +
            attributeIfContent("Order", order)
        ]
    ]
[/#function]

[#function getListenerRuleRedirectAction protocol port host path query permanent=true order=""]
    [#return
        [
            {
                "Type": "redirect",
                "RedirectConfig": {
                    "Protocol": protocol,
                    "Port": port,
                    "Host": host,
                    "Path": path?ensure_starts_with("/"),
                    "Query": query,
                    "StatusCode": valueIfTrue("HTTP_301", permanent, "HTTP_302")
                }
            } +
            attributeIfContent("Order", order)
        ]
    ]
[/#function]

[#function getListenerRuleFixedAction message contentType statusCode order=""]
    [#return
        [
            {
                "Type": "fixed-response",
                "FixedResponseConfig": {
                    "MessageBody": message,
                    "ContentType": contentType,
                    "StatusCode": statusCode
                }
            } +
            attributeIfContent("Order", order)
        ]
    ]
[/#function]

[#function getListenerRuleAuthCognitoAction 
        userPoolArn 
        userPoolClientId 
        userPoolDomain 
        userPoolSessionCookieName 
        userPoolSessionTimeout
        userPoolOauthScope
        order=""]
        
    [#return 
        [
            {
                "Type" : "authenticate-cognito",
                "AuthenticateCognitoConfig" : {
                    "UserPoolArn" : userPoolArn,
                    "UserPoolClientId" : userPoolClientId,
                    "UserPoolDomain" : userPoolDomain,
                    "SessionCookieName" : userPoolSessionCookieName,
                    "SessionTimeout" : userPoolSessionTimeout,
                    "Scope" : userPoolOauthScope,
                    "OnUnauthenticatedRequest" : "authenticate"
                }
            } + 
            attributeIfContent("Order", order)
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

[#function getListenerRuleHostCondition hosts ]
    [#return 
        [
            {
                "Field" : "host-header",
                "Values" : asArray(hosts)
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
                "Actions" : asArray(actions),
                "Conditions": asArray(conditions),
                "ListenerArn" : getReference(listenerId, ARN_ATTRIBUTE_TYPE)
            }
        outputs=ALB_LISTENER_RULE_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]

[#macro createClassicLB mode id name shortName tier component 
            listeners 
            healthCheck 
            securityGroups 
            idleTimeout 
            deregistrationTimeout
            policies=[]
            stickinessPolicies=[] 
            logs=false 
            bucket="" 
            dependencies="" ]
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
                "LoadBalancerName" : shortName,
                "ConnectionSettings" : {
                    "IdleTimeout" : idleTimeout
                }
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
            ) + 
            ( deregistrationTimeout > 0 )?then(
                {
                    "ConnectionDrainingPolicy" : {
                        "Enabled" : true,
                        "Timeout" : deregistrationTimeout
                    }
                },
                {}
            ) + 
            attributeIfContent(
                "LBCookieStickinessPolicy",
                stickinessPolicies
            ) +
            attributeIfContent(
                "Policies",
                policies
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