[#-- ALB --]
[#if component.ALB??]
    [@securityGroup solutionListMode tier component /]
    [#assign alb = component.ALB]
    [#if resourceCount > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
            [#list alb.PortMappings as mapping]
                [#assign source = ports[portMappings[mapping].Source]]
                [#assign destination = ports[portMappings[mapping].Destination]]
                "${formatId("securityGroupIngress", tier.Id, component.Id, source.Port?c)}" : {
                    "Type" : "AWS::EC2::SecurityGroupIngress",
                    "Properties" : {
                        "GroupId": {"Ref" : "${formatId("securityGroup", tier.Id, component.Id)}"},
                        "IpProtocol": "${source.IPProtocol}",
                        "FromPort": "${source.Port?c}",
                        "ToPort": "${source.Port?c}",
                        "CidrIp": "0.0.0.0/0"
                    }
                },
                "${formatId("listener", tier.Id, component.Id, source.Port?c)}" : {
                    "Type" : "AWS::ElasticLoadBalancingV2::Listener",
                    "Properties" : {
                        [#if (source.Certificate)?? && source.Certificate]
                            "Certificates" : [
                                {
                                    "CertificateArn" :
                                        [#if (alb.DNS[mapping])??]
                                            [#assign certificateLink = alb.DNS[mapping]]
                                            "${getKey("certificate", certificateLink.Tier, certificateLink.Component)}"
                                        [#else]
                                            [#if getKey("certificate", certificateId)??]
                                                "${getKey("certificate", certificateId)}"
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
                              "TargetGroupArn" : { "Ref" : "${formatId("tg", tier.Id, component.Id, source.Port?c, "default")}" },
                              "Type" : "forward"
                            }
                        ],
                        "LoadBalancerArn" : { "Ref" : "${formatId("alb", tier.Id, component.Id)}" },
                        "Port" : ${source.Port?c},
                        "Protocol" : "${source.Protocol}"
                    }
                },
                [@createTargetGroup tier=tier component=component source=source destination=destination name="default" /],
            [/#list]
            "${formatId("alb", tier.Id, component.Id)}" : {
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
                            "${getKey("subnet", tier.Id, zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
                        [/#list]
                    ],
                    "Scheme" : "${(tier.RouteTable == "external")?string("internet-facing","internal")}",
                    "SecurityGroups":[ {"Ref" : "${formatId("securityGroup", tier.Id, component.Id)}"} ],
                    "Name" : "${formatName(productId, segmentId, tier.Id, component.Id)}",
                    "Tags" : [
                        { "Key" : "cot:request", "Value" : "${requestReference}" },
                        { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                        { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                        { "Key" : "cot:account", "Value" : "${accountId}" },
                        { "Key" : "cot:product", "Value" : "${productId}" },
                        { "Key" : "cot:segment", "Value" : "${segmentId}" },
                        { "Key" : "cot:environment", "Value" : "${environmentId}" },
                        { "Key" : "cot:category", "Value" : "${categoryId}" },
                        { "Key" : "cot:tier", "Value" : "${tier.Id}" },
                        { "Key" : "cot:component", "Value" : "${component.Id}" },
                        { "Key" : "Name", "Value" : "${formatName(productName, segmentName, tier.Name, component.Name)}" }
                    ]
                }
            }
            [#break]
        [#case "outputs"]
            [#list alb.PortMappings as mapping]
                [#assign source = ports[portMappings[mapping].Source]]
                "${formatId("listener", tier.Id, component.Id, source.Port?c)}" : {
                    "Value" : { "Ref" : "${formatId("listener", tier.Id, component.Id, source.Port?c)}" }
                },
                "${formatId("tg", tier.Id, component.Id, source.Port?c, "default")}" : {
                    "Value" : { "Ref" : "${formatId("tg", tier.Id, component.Id, source.Port?c, "default")}" }
                },
            [/#list]
            "${formatId("alb", tier.Id, component.Id)}" : {
                "Value" : { "Ref" : "${formatId("alb", tier.Id, component.Id)}" }
            },
            "${formatId("alb", tier.Id, component.Id, "dns")}" : {
                "Value" : { "Fn::GetAtt" : ["${formatId("alb", tier.Id, component.Id)}", "DNSName"] }
            }
            [#break]
    [/#switch]
    [#assign resourceCount += 1]
[/#if]