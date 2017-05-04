[#-- ALB --]
[#if componentType == "alb"]
    [@createSecurityGroup solutionListMode tier component /]
    [#assign albSecurityGroupResourceId = formatComponentSecurityGroupResourceId(tier, component)]

    [#assign alb = component.ALB]
    
    [#assign albResourceId = formatALBResourceId(tier, component)]
    
    [#if resourceCount > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
            [#list alb.PortMappings as mapping]
                [#assign source = ports[portMappings[mapping].Source]]
                [#assign destination = ports[portMappings[mapping].Destination]]
                [#assign albListenerResourceId = formatALBListenerResourceId(
                                                    tier,
                                                    component,
                                                    source)]
                [#assign albListenerSecurityGroupIngressResourceId = formatALBListenerSecurityGroupIngressResourceId(
                                                    tier,
                                                    component,
                                                    source)]
                [#assign albTargetGroupResourceId = formatALBTargetGroupResourceId(
                                                    tier,
                                                    component,
                                                    source,
                                                    "default")]
                "${albListenerSecurityGroupIngressResourceId}" : {
                    "Type" : "AWS::EC2::SecurityGroupIngress",
                    "Properties" : {
                        "GroupId": {"Ref" : "${albSecurityGroupResourceId}"},
                        "IpProtocol": "${source.IPProtocol}",
                        "FromPort": "${source.Port?c}",
                        "ToPort": "${source.Port?c}",
                        "CidrIp": "0.0.0.0/0"
                    }
                },
                "${albListenerResourceId}" : {
                    "Type" : "AWS::ElasticLoadBalancingV2::Listener",
                    "Properties" : {
                        [#if (source.Certificate)?? && source.Certificate]
                            "Certificates" : [
                                {
                                    [#assign certificateFound = false]
                                    "CertificateArn" :
                                        [#if (alb.DNS[mapping])??]
                                            [#assign certificateLink = alb.DNS[mapping]]
                                            [#assign certificateResourceId = formatComponentCertificateResourceId(
                                                                                tier,
                                                                                component)]
                                            [#if getKey(certificateResourceId)??]
                                                "${getKey(certificateResourceId)}"
                                                [#assign certificateFound = true]
                                            [/#if]
                                        [/#if]
                                        [#if !certificateFound]
                                            [#assign certificateResourceId = formatCertificateResourceId(
                                                                                certificateId)]
                                            [#if getKey(certificateResourceId)??]
                                                "${getKey(certificateResourceId)}"
                                            [#else]
                                                {
                                                    "Fn::Join" : [
                                                        "",
                                                        [
                                                            "arn:aws:iam::",
                                                            {"Ref" : "AWS::AccountId"},
                                                            ":server-certificate/ssl/${certificateId}/${certificateId}-ssl"
                                                        ]
                                                    ]
                                                }
                                            [/#if]
                                        [/#if]
                                }
                            ],
                        [/#if]
                        "DefaultActions" : [
                            {
                              "TargetGroupArn" : { "Ref" : "${albTargetGroupResourceId}" },
                              "Type" : "forward"
                            }
                        ],
                        "LoadBalancerArn" : { "Ref" : "${albResourceId}" },
                        "Port" : ${source.Port?c},
                        "Protocol" : "${source.Protocol}"
                    }
                },
                [@createTargetGroup tier component source destination "default" /],
            [/#list]

            "${albResourceId}" : {
                "Type" : "AWS::ElasticLoadBalancingV2::LoadBalancer",
                "Properties" : {
                    [#if (alb.Logs)?? && alb.Logs]
                        "LoadBalancerAttributes" : [
                            {
                                "Key" : "access_logs.s3.enabled",
                                "Value" : true
                            },
                            {
                                "Key" : "access_logs.s3.bucket",
                                "Value" : "${operationsBucket}"
                            },
                            {
                                "Key" : "access_logs.s3.prefix",
                                "Value" : ""
                            }
                        ],
                    [/#if]
                    "Subnets" : [
                        [#list zones as zone]
                            "${getKey(formatVPCSubnetResourceId(
                                        tier,
                                        zone))}"
                            [#if !(zones?last.Id == zone.Id)],[/#if]
                        [/#list]
                    ],
                    "Scheme" : "${(tier.RouteTable == "external")?string("internet-facing","internal")}",
                    "SecurityGroups":[ {"Ref" : "${albSecurityGroupResourceId}"} ],
                    "Name" : "${formatComponentShortFullNameStem(
                                    tier,
                                    component)}",
                    "Tags" : [
                        { "Key" : "cot:request", "Value" : "${requestReference}" },
                        { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                        { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                        { "Key" : "cot:account", "Value" : "${accountId}" },
                        { "Key" : "cot:product", "Value" : "${productId}" },
                        { "Key" : "cot:segment", "Value" : "${segmentId}" },
                        { "Key" : "cot:environment", "Value" : "${environmentId}" },
                        { "Key" : "cot:category", "Value" : "${categoryId}" },
                        { "Key" : "cot:tier", "Value" : "${tierId}" },
                        { "Key" : "cot:component", "Value" : "${componentId}" },
                        { "Key" : "Name", "Value" : "${componentFullNameStem}" }
                    ]
                }
            }
            [#break]
        [#case "outputs"]
            [#list alb.PortMappings as mapping]
                [#assign source = ports[portMappings[mapping].Source]]
                [#assign albListenerResourceId = formatALBListenerResourceId(
                                                    tier,
                                                    component,
                                                    source)]
                [#assign albTargetGroupResourceId = formatALBTargetGroupResourceId(
                                                    tier,
                                                    component,
                                                    source,
                                                    "default")]
                "${albListenerResourceId}" : {
                    "Value" : { "Ref" : "${albListenerResourceId}" }
                },
                "${albTargetGroupResourceId}" : {
                    "Value" : { "Ref" : "${albTargetGroupResourceId}" }
                },
            [/#list]
            "${albResourceId}" : {
                "Value" : { "Ref" : "${albResourceId}" }
            },
            "${formatResourceDnsAttributeId(albResourceId)}" : {
                "Value" : { "Fn::GetAtt" : ["${albResourceId}", "DNSName"] }
            }
            [#break]
    [/#switch]
    [#assign resourceCount += 1]
[/#if]