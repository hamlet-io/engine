[#-- ALB --]

[#assign ALB_OUTPUT_MAPPINGS =
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
[#assign outputMappings +=
    {
        ALB_RESOURCE_TYPE : ALB_OUTPUT_MAPPINGS
    }
]

[#macro createALB mode id name shortName tier component securityGroups logs=false bucket=""]
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::ElasticLoadBalancingV2::LoadBalancer"
        properties=
            {
                "Subnets" : getSubnets(tier),
                "Scheme" : (tier.RouteTable == "external")?then("internet-facing","internal"),
                "SecurityGroups": securityGroups,
                "Name" : shortName
            } +
            logs?then(
                {
                    "LoadBalancerAttributes" : [
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
                    ]
                },
                {}
            ) 
        tags=getCfTemplateCoreTags(name, tier, component)
        outputs=ALB_OUTPUT_MAPPINGS
    /]
[/#macro]

[#macro createALBListener mode id port albId defaultTargetGroupId certificateLink={}]

    [#assign acmCert =
        certificateLink?has_content?then(
            getExistingReference(
                formatComponentCertificateId(
                    certificateLink.Tier,
                    certificateLink.Component),
                "",
                region),
            "")
    ]
    [#if !(acmCert?has_content)]
        [#assign acmCert =
            getExistingReference(
                formatCertificateId(
                    productDomain),
                "",
                region)
        ]
    [/#if]
    [#if !(acmCert?has_content)]
        [#assign acmCert =
            getExistingReference(
                formatCertificateId(
                    certificateId),
                "",
                region)
        ]
    [/#if]

    [@cfTemplate
        mode=mode
        id=id
        type="AWS::ElasticLoadBalancingV2::Listener"
        properties=
            {
                "DefaultActions" : [
                    {
                      "TargetGroupArn" : getReference(albTargetGroupId),
                      "Type" : "forward"
                    }
                ],
                "LoadBalancerArn" : getReference(albId),
                "Port" : port.Port,
                "Protocol" : port.Protocol
            } +
            port.Certificate?has_content?then(
                {
                    "Certificates" : [
                        {
                            "CertificateArn" :
                                acmCert?has_content?then(
                                    acmCert,
                                    {
                                        "Fn::Join" : [
                                            "",
                                            [
                                                "arn:aws:iam::",
                                                {"Ref" : "AWS::AccountId"},
                                                ":server-certificate/ssl/",
                                                certificateId,
                                                "/",
                                                certificateId,
                                                "-ssl"
                                            ]
                                        ]
                                    }
                                )
                        }
                    ],
                    "SslPolicy" : "ELBSecurityPolicy-TLS-1-2-2017-01"
                },
                {}
            )
    /]
[/#macro]

[#macro createTargetGroup mode id name tier component source destination extensions=""]
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::ElasticLoadBalancingV2::TargetGroup"
        properties=
            {
                "HealthCheckPort" : (destination.HealthCheck.Port)!"traffic-port",
                "HealthCheckProtocol" : (destination.HealthCheck.Protocol)!destination.Protocol,
                "HealthCheckPath" : destination.HealthCheck.Path,
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
            (destination.HealthCheck.SuccessCodes)?has_content?then(
                {
                    "Matcher" : { "HttpCode" : destination.HealthCheck.SuccessCodes }
                },
                {}
            )
        tags=
            getCfTemplateCoreTags(
                formatComponentFullName(
                    tier, 
                    component,
                    extensions,
                    source.Port, 
                    name),
                tier,
                component)
    /]
[/#macro]
