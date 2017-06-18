[#-- ELB --]
[#if componentType == "elb"]
    [#assign elb = component.ELB]

    [#assign elbId = formatELBId(tier, component)]
    [#assign elbFullName = componentFullName]
    [#assign elbShortFullName = componentShortFullName]

    [@createComponentSecurityGroup solutionListMode tier component /]

    [#switch solutionListMode]
        [#case "definition"]
            [#list elb.PortMappings as mapping]
                [#assign source = ports[portMappings[mapping].Source]]
                [@checkIfResourcesCreated /]
                "${formatId("securityGroupIngress", componentIdStem, source.Port?c)}" : {
                    "Type" : "AWS::EC2::SecurityGroupIngress",
                    "Properties" : {
                        "GroupId": {"Ref" : "${formatComponentSecurityGroupId(
                                                tier,
                                                component)}"},
                        "IpProtocol": "${source.IPProtocol}",
                        "FromPort": "${source.Port?c}",
                        "ToPort": "${source.Port?c}",
                        "CidrIp": "0.0.0.0/0"
                    }
                }
                [@resourcesCreated /]
            [/#list]
            [@checkIfResourcesCreated /]
            "${elbId}" : {
                "Type" : "AWS::ElasticLoadBalancing::LoadBalancer",
                "Properties" : {
                    [#if multiAZ]
                        "Subnets" : [
                            [#list zones as zone]
                                "${getKey("subnet", tierId, zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
                            [/#list]
                        ],
                        "CrossZone" : true,
                    [#else]
                        "Subnets" : [
                            "${getKey("subnet", tierId, zones[0].Id)}"
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
                                [#if (source.Certificate)?has_content]
                                    ,"SSLCertificateId" :
                                        [#if getKey("certificate", certificateId)?has_content]
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
                    "SecurityGroups":[ {"Ref" : "${formatComponentSecurityGroupId(
                                                    tier,
                                                    component)}"} ],
                    "LoadBalancerName" : "${elbShortFullName}",
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
                        { "Key" : "Name", "Value" : "${elbFullName}" }
                    ]
                }
            }
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output elbId /]
            [@outputLBDns elbId /]
            [#break]

    [/#switch]
[/#if]