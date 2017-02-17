[#-- ALB --]
[#if component.ALB??]
    [#assign alb = component.ALB]
    [#if count > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
                            [#list alb.PortMappings as mapping]
                                [#assign source = ports[portMappings[mapping].Source]]
                                [#assign destination = ports[portMappings[mapping].Destination]]
                                "securityGroupIngressX${tier.Id}X${component.Id}X${source.Port?c}" : {
                                    "Type" : "AWS::EC2::SecurityGroupIngress",
                                    "Properties" : {
                                        "GroupId": {"Ref" : "securityGroupX${tier.Id}X${component.Id}"},
                                        "IpProtocol": "${source.IPProtocol}",
                                        "FromPort": "${source.Port?c}",
                                        "ToPort": "${source.Port?c}",
                                        "CidrIp": "0.0.0.0/0"
                                    }
                                },
                                "listenerX${tier.Id}X${component.Id}X${source.Port?c}" : {
                                    "Type" : "AWS::ElasticLoadBalancingV2::Listener",
                                    "Properties" : {
                                        [#if (source.Certificate)?? && source.Certificate]
                                            "Certificates" : [
                                                {
                                                    "CertificateArn" :
                                                        [#if getKey("certificateX" + certificateId)??]
                                                            "${getKey("certificateX" + certificateId)}"
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
                                                }
                                            ],
                                        [/#if]
                                        "DefaultActions" : [
                                            {
                                              "TargetGroupArn" : { "Ref" : "tgX${tier.Id}X${component.Id}X${source.Port?c}Xdefault" },
                                              "Type" : "forward"
                                            }
                                        ],
                                        "LoadBalancerArn" : { "Ref" : "albX${tier.Id}X${component.Id}" },
                                        "Port" : ${source.Port?c},
                                        "Protocol" : "${source.Protocol}"
                                    }
                                },
                                [@createTargetGroup tier=tier component=component source=source destination=destination name="default" /],
                            [/#list]
                            "albX${tier.Id}X${component.Id}" : {
                                "Type" : "AWS::ElasticLoadBalancingV2::LoadBalancer",
                                "Properties" : {
                                    "Subnets" : [
                                        [#list zones as zone]
                                            "${getKey("subnetX"+tier.Id+"X"+zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
                                        [/#list]
                                    ],
                                    "Scheme" : "${(tier.RouteTable == "external")?string("internet-facing","internal")}",
                                    "SecurityGroups":[ {"Ref" : "securityGroupX${tier.Id}X${component.Id}"} ],
                                    "Name" : "${productId}-${segmentId}-${tier.Id}-${component.Id}",
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
                                        { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}" }
                                    ]
                                }
                            }
            [#break]
        [#case "outputs"]
                            [#list alb.PortMappings as mapping]
                                [#assign source = ports[portMappings[mapping].Source]]
                                "listenerX${tier.Id}X${component.Id}X${source.Port?c}" : {
                                    "Value" : { "Ref" : "listenerX${tier.Id}X${component.Id}X${source.Port?c}" }
                                },
                                "tgX${tier.Id}X${component.Id}X${source.Port?c}Xdefault" : {
                                    "Value" : { "Ref" : "tgX${tier.Id}X${component.Id}X${source.Port?c}Xdefault" }
                                },
                            [/#list]
                            "albX${tier.Id}X${component.Id}" : {
                                "Value" : { "Ref" : "albX${tier.Id}X${component.Id}" }
                            },
                            "albX${tier.Id}X${component.Id}Xdns" : {
                                "Value" : { "Fn::GetAtt" : ["albX${tier.Id}X${component.Id}", "DNSName"] }
                            }
            [#break]
    [/#switch]
    [#assign count += 1]
[/#if]