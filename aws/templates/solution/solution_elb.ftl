[#-- ELB --]
[#if component.ELB??]
    [@securityGroup solutionListMode tier component /]
    [#assign elb = component.ELB]
    [#if resourceCount > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
            [#list elb.PortMappings as mapping]
                [#assign source = ports[portMappings[mapping].Source]]
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
            [/#list]
            "${formatId("elb", tier.Id, component.Id)}" : {
                "Type" : "AWS::ElasticLoadBalancing::LoadBalancer",
                "Properties" : {
                    [#if multiAZ]
                        "Subnets" : [
                            [#list zones as zone]
                                "${getKey("subnet", tier.Id, zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
                            [/#list]
                        ],
                        "CrossZone" : true,
                    [#else]
                        "Subnets" : [
                            "${getKey("subnet", tier.Id, zones[0].Id)}"
                        ],
                    [/#if]
                    "Listeners" : [
                        [#list elb.PortMappings as mapping]
                            [#assign source = ports[portMappings[mapping].Source]]
                            [#assign destination = ports[portMappings[mapping].Destination]]
                            {
                                "LoadBalancerPort" : "${source.Port?c}",
                                "Protocol" : "${source.Protocol}",
                                "InstancePort" : "${destination.Port?c}",
                                "InstanceProtocol" : "${destination.Protocol}"
                                [#if (source.Certificate)?? && source.Certificate]
                                    ,"SSLCertificateId" :
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
                            [#if !(mapping == elb.PortMappings?last)],[/#if]
                        [/#list]
                    ],
                    "HealthCheck" : {
                        [#assign destination = ports[portMappings[elb.PortMappings[0]].Destination]]
                        "Target" : "${(destination.HealthCheck.Protocol)!destination.Protocol}:${destination.Port?c}${(elb.HealthCheck.Path)!destination.HealthCheck.Path}",
                        "HealthyThreshold" : "${(elb.HealthCheck.HealthyThreshold)!destination.HealthCheck.HealthyThreshold}",
                        "UnhealthyThreshold" : "${(elb.HealthCheck.UnhealthyThreshold)!destination.HealthCheck.UnhealthyThreshold}",
                        "Interval" : "${(elb.HealthCheck.Interval)!destination.HealthCheck.Interval}",
                        "Timeout" : "${(elb.HealthCheck.Timeout)!destination.HealthCheck.Timeout}"
                    },
                    [#if (elb.Logs)?? && (elb.Logs == true)]
                        "AccessLoggingPolicy" : {
                            "EmitInterval" : 5,
                            "Enabled" : true,
                            "S3BucketName" : "${operationsBucket}"
                        },
                    [/#if]
                    "Scheme" : "${(tier.RouteTable == "external")?string("internet-facing","internal")}",
                    "SecurityGroups":[ {"Ref" : "${formatId("securityGroup", tier.Id, component.Id)}"} ],
                    "LoadBalancerName" : "${formatName(productId, segmentId, tier.Id, component.Id)}",
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
            "${formatId("elb", tier.Id, component.Id)}" : {
                "Value" : { "Ref" : "${formatId("elb", tier.Id, component.Id)}" }
            },
            "${formatId("elb", tier.Id, component.Id, "dns")}" : {
                "Value" : { "Fn::GetAtt" : ["${formatId("elb", tier.Id, component.Id)}", "DNSName"] }
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]