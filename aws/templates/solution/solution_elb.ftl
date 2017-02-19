[#-- ELB --]
[#if component.ELB??]
    [#assign elb = component.ELB]
    [#if count > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
            [#list elb.PortMappings as mapping]
                [#assign source = ports[portMappings[mapping].Source]]
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
            [/#list]
            "elbX${tier.Id}X${component.Id}" : {
                "Type" : "AWS::ElasticLoadBalancing::LoadBalancer",
                "Properties" : {
                    [#if multiAZ]
                        "Subnets" : [
                            [#list zones as zone]
                                "${getKey("subnetX"+tier.Id+"X"+zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
                            [/#list]
                        ],
                        "CrossZone" : true,
                    [#else]
                        "Subnets" : [
                            "${getKey("subnetX"+tier.Id+"X"+zones[0].Id)}"
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
                    "SecurityGroups":[ {"Ref" : "securityGroupX${tier.Id}X${component.Id}"} ],
                    "LoadBalancerName" : "${productId}-${segmentId}-${tier.Id}-${component.Id}",
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
            "elbX${tier.Id}X${component.Id}" : {
                "Value" : { "Ref" : "elbX${tier.Id}X${component.Id}" }
            },
            "elbX${tier.Id}X${component.Id}Xdns" : {
                "Value" : { "Fn::GetAtt" : ["elbX${tier.Id}X${component.Id}", "DNSName"] }
            }
            [#break]

    [/#switch]
    [#assign count += 1]
[/#if]