[#ftl]

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
        },
        NAME_ATTRIBUTE_TYPE : {
            "Attribute" : "LoadBalancerFullName"
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

[#assign lbMappings =
    {
        AWS_LB_RESOURCE_TYPE : LB_OUTPUT_MAPPINGS,
        AWS_ALB_RESOURCE_TYPE : LB_OUTPUT_MAPPINGS,
        AWS_LB_CLASSIC_RESOURCE_TYPE : LB_OUTPUT_MAPPINGS,
        AWS_LB_APPLICATION_RESOURCE_TYPE : LB_OUTPUT_MAPPINGS,
        AWS_LB_NETWORK_RESOURCE_TYPE : LB_OUTPUT_MAPPINGS,
        AWS_ALB_LISTENER_RESOURCE_TYPE : ALB_LISTENER_OUTPUT_MAPPINGS,
        AWS_ALB_LISTENER_RULE_RESOURCE_TYPE : ALB_LISTENER_RULE_OUTPUT_MAPPINGS,
        AWS_ALB_TARGET_GROUP_RESOURCE_TYPE : ALB_TARGET_GROUP_OUTPUT_MAPPINGS
    }
]

[#list lbMappings as type, mappings]
    [@addOutputMapping
        provider=AWS_PROVIDER
        resourceType=type
        mappings=mappings
    /]
[/#list]

[#assign metricAttributes +=
    {
        AWS_LB_CLASSIC_RESOURCE_TYPE : {
            "Namespace" : "AWS/ELB",
            "Dimensions" : {
                "LoadBalancerName" : {
                    "Output" : ""
                }
            }
        },
        AWS_LB_APPLICATION_RESOURCE_TYPE : {
            "Namespace" : "AWS/ApplicationELB",
            "Dimensions" : {
                "LoadBalancer" : {
                    "Output" : NAME_ATTRIBUTE_TYPE
                }
            }
        },
        AWS_LB_NETWORK_RESOURCE_TYPE : {
            "Namespace" : "AWS/NetworkELB",
            "Dimensions" : {
                "LoadBalancer" : {
                    "Output" : NAME_ATTRIBUTE_TYPE
                }
            }
        }
    }
]

[#macro createALB
    id
    name
    shortName
    tier
    component
    securityGroups
    type
    idleTimeout
    publicEndpoint
    networkResources
    logs=false
    bucket=""]

    [#assign loadBalancerAttributes =
        ( type == "application" )?then(
            [
                {
                    "Key" : "idle_timeout.timeout_seconds",
                    "Value" : idleTimeout?c
                }
            ],
            []
        ) +
        (logs && type == "application")?then(
            [
                {
                    "Key" : "access_logs.s3.enabled",
                    "Value" : "true"
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
        ) +
        ( type == "network" )?then(
            [
                {
                    "Key" : "load_balancing.cross_zone.enabled",
                    "Value" : "true"
                }
            ],
            []
        )
    ]

    [@cfResource
        id=id
        type="AWS::ElasticLoadBalancingV2::LoadBalancer"
        properties=
            {
                "Subnets" : getSubnets(tier, networkResources),
                "Scheme" : (publicEndpoint)?then("internet-facing","internal"),
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

[#macro createALBListener id port albId defaultTargetGroupId certificateId="" sslPolicy="" ]

    [@cfResource
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

[#macro createTargetGroup id name tier component destination attributes vpcId targetType=""]

    [#local healthCheckProtocol = ((destination.HealthCheck.Protocol)!destination.Protocol)?upper_case]

    [#local targetGroupAttributes = [] ]
    [#list attributes as key,value ]
        [#local targetGroupAttributes +=
            [
                {
                    "Key" : key,
                    "Value" : (value?is_string)?then(
                                    value,
                                    value?c
                                )
                }
            ]]
    [/#list]

    [@cfResource
        id=id
        type="AWS::ElasticLoadBalancingV2::TargetGroup"
        properties=
            {
                "HealthCheckPort" : (destination.HealthCheck.Port)!"traffic-port",
                "HealthCheckProtocol" : healthCheckProtocol,
                "HealthCheckIntervalSeconds" : destination.HealthCheck.Interval?number,
                "HealthyThresholdCount" : destination.HealthCheck.HealthyThreshold?number,
                "Port" : destination.Port,
                "Protocol" : (destination.Protocol)?upper_case,
                "VpcId": getReference(vpcId),
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
                    "HealthCheckTimeoutSeconds" : destination.HealthCheck.Timeout?number,
                    "UnhealthyThresholdCount" : destination.HealthCheck.UnhealthyThreshold?number
                },
                {
                    "UnhealthyThresholdCount" : destination.HealthCheck.HealthyThreshold?number
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

[#macro createListenerRule id listenerId actions=[] conditions=[] priority=100 dependencies=""]
    [@cfResource
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

[#macro createClassicLB id name shortName tier component
            listeners
            healthCheck
            securityGroups
            idleTimeout
            deregistrationTimeout
            networkResources
            publicEndpoint
            policies=[]
            stickinessPolicies=[]
            logs=false
            bucket=""
            dependencies="" ]
        [@cfResource
        id=id
        type="AWS::ElasticLoadBalancing::LoadBalancer"
        properties=
            {
                "Listeners" : listeners,
                "HealthCheck" : healthCheck,
                "Scheme" :
                    (publicEndpoint)?then(
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
                    "Subnets" : getSubnets(tier, networkResources),
                    "CrossZone" : true
                },
                {
                    "Subnets" : [ getSubnets(tier, networkResources)[0] ]
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
        outputs=LB_OUTPUT_MAPPINGS +
                    {
                        NAME_ATTRIBUTE_TYPE : {
                            "UseRef" : true
                        }
                    }
        dependencies=dependencies
    /]
[/#macro]
