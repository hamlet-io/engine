[#-- ALB --]
[#if componentType == "alb"]
    [@createSecurityGroup solutionListMode tier component componentIdStem componentFullNameStem /]
    [#assign alb = component.ALB]
    [#if resourceCount > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
            [#list alb.PortMappings as mapping]
                [#assign source = ports[portMappings[mapping].Source]]
                [#assign destination = ports[portMappings[mapping].Destination]]
                "${formatId("securityGroupIngress", componentIdStem, source.Port?c)}" : {
                    "Type" : "AWS::EC2::SecurityGroupIngress",
                    "Properties" : {
                        "GroupId": {"Ref" : "${formatSecurityGroupPrimaryResourceId(componentIdStem)}"},
                        "IpProtocol": "${source.IPProtocol}",
                        "FromPort": "${source.Port?c}",
                        "ToPort": "${source.Port?c}",
                        "CidrIp": "0.0.0.0/0"
                    }
                },
                "${formatId("listener", componentIdStem, source.Port?c)}" : {
                    "Type" : "AWS::ElasticLoadBalancingV2::Listener",
                    "Properties" : {
                        [#if (source.Certificate)?? && source.Certificate]
                            "Certificates" : [
                                {
                                    [#assign certificateFound = false]
                                    "CertificateArn" :
                                        [#if (alb.DNS[mapping])??]
                                            [#assign certificateLink = alb.DNS[mapping]]
                                            [#if getKey("certificate", certificateLink.Tier, certificateLink.Component)??]
                                                "${getKey("certificate", certificateLink.Tier, certificateLink.Component)}"
                                                [#assign certificateFound = true]
                                            [/#if]
                                        [/#if]
                                        [#if !certificateFound]
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
                              "TargetGroupArn" : { "Ref" : "${formatId("tg", componentIdStem, source.Port?c, "default")}" },
                              "Type" : "forward"
                            }
                        ],
                        "LoadBalancerArn" : { "Ref" : "${primaryResourceIdStem}" },
                        "Port" : ${source.Port?c},
                        "Protocol" : "${source.Protocol}"
                    }
                },
                [@createTargetGroup tierId componentId componentIdStem componentFullNameStem source destination "default" /],
            [/#list]
            "${primaryResourceIdStem}" : {
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
                            "${getKey("subnet", tierId, zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
                        [/#list]
                    ],
                    "Scheme" : "${(tier.RouteTable == "external")?string("internet-facing","internal")}",
                    "SecurityGroups":[ {"Ref" : "${formatSecurityGroupPrimaryResourceId(componentIdStem)}"} ],
                    "Name" : "${formatName(productId, segmentId, tierId, componentId)}",
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
                "${formatId("listener", componentIdStem, source.Port?c)}" : {
                    "Value" : { "Ref" : "${formatId("listener", componentIdStem, source.Port?c)}" }
                },
                "${formatId("tg", componentIdStem, source.Port?c, "default")}" : {
                    "Value" : { "Ref" : "${formatId("tg", componentIdStem, source.Port?c, "default")}" }
                },
            [/#list]
            "${primaryResourceIdStem}" : {
                "Value" : { "Ref" : "${primaryResourceIdStem}" }
            },
            "${formatId(primaryResourceIdStem, "dns")}" : {
                "Value" : { "Fn::GetAtt" : ["${primaryResourceIdStem}", "DNSName"] }
            }
            [#break]
    [/#switch]
    [#assign resourceCount += 1]
[/#if]