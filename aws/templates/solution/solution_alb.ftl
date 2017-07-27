[#-- ALB --]
[#if componentType == "alb"]
    [#assign alb = component.ALB]

    [#assign albId = formatALBId(tier, component)]
    [#assign albFullName = componentFullName]
    [#assign albShortFullName = componentShortFullName]

    [#assign albSecurityGroupId = formatALBSecurityGroupId(tier, component)]
    [@createComponentSecurityGroup solutionListMode tier component /]
    [#list alb.PortMappings as mapping]
        [#assign source = ports[portMappings[mapping].Source]]
        [#assign destination = ports[portMappings[mapping].Destination]]
        [@createTargetGroup solutionListMode tier component source destination "default" /]
    [/#list]

    [#switch solutionListMode]
        [#case "definition"]
            [#list alb.PortMappings as mapping]
                
                [#assign sourceMapping =
                            mapping?is_hash?then(
                                mapping.Mapping,
                                mapping)]
                [#assign source = portMappings[sourceMapping].Source]
                [#assign sourcePort = ports[source]]
                [#assign sourceIPAddressGroups =
                            mapping?is_hash?then(
                                mapping.IPAddressGroups!alb.IPAddressGroups![],
                                alb.IPAddressGroups![])]
                [#assign albListenerId =
                            formatALBListenerId(
                                tier,
                                component,
                                sourcePort)]
                [#assign albListenerSecurityGroupIngressId =
                            formatALBListenerSecurityGroupIngressId(
                                tier,
                                component,
                                sourcePort)]
                [#assign albTargetGroupId =
                            formatALBTargetGroupId(
                                tier,
                                component,
                                sourcePort,
                                "default")]
                [@createSecurityGroupIngress
                    solutionListMode,
                    albListenerSecurityGroupIngressId,
                    source,
                    getUsageCIDRs(
                        source,
                        sourceIPAddressGroups),
                    albSecurityGroupId
                /]
                [@checkIfResourcesCreated /]
                "${albListenerId}" : {
                    "Type" : "AWS::ElasticLoadBalancingV2::Listener",
                    "Properties" : {
                        [#if (sourcePort.Certificate)?has_content]
                            "Certificates" : [
                                {
                                    [#assign certificateFound = false]
                                    "CertificateArn" :
                                        [#if (alb.DNS[mapping])??]
                                            [#assign certificateLink = alb.DNS[mapping]]
                                            [#assign mappingCertificateId = formatComponentCertificateId(
                                                                                certificateLink.Tier,
                                                                                certificateLink.Component)]
                                            [#if getKey(mappingCertificateId)?has_content]
                                                "${getKeyByRegion(region, mappingCertificateId)}"
                                                [#assign certificateFound = true]
                                            [/#if]
                                        [/#if]
                                        [#if !certificateFound]
                                            [#assign acmCertificateId = formatCertificateId(
                                                                            certificateId)]
                                            [#if getKeyByRegion(region, acmCertificateId)?has_content]
                                                "${getKeyByRegion(region, acmCertificateId)}"
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
                            "SslPolicy" : "ELBSecurityPolicy-TLS-1-2-2017-01",
                        [/#if]
                        "DefaultActions" : [
                            {
                              "TargetGroupArn" : { "Ref" : "${albTargetGroupId}" },
                              "Type" : "forward"
                            }
                        ],
                        "LoadBalancerArn" : { "Ref" : "${albId}" },
                        "Port" : ${sourcePort.Port?c},
                        "Protocol" : "${sourcePort.Protocol}"
                    }
                }
                [@resourcesCreated /]
            [/#list]

            [@checkIfResourcesCreated /]
            "${albId}" : {
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
                            "${getKey(formatSubnetId(
                                        tier,
                                        zone))}"
                            [#sep],[/#sep]
                        [/#list]
                    ],
                    "Scheme" : "${(tier.RouteTable == "external")?string("internet-facing","internal")}",
                    "SecurityGroups":[ {"Ref" : "${albSecurityGroupId}"} ],
                    "Name" : "${albShortFullName}",
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
                        { "Key" : "Name", "Value" : "${albFullName}" }
                    ]
                }
            }
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output albId /]
            [@outputLBDns albId /]
            [#list alb.PortMappings as mapping]
                [#assign source = ports[portMappings[mapping].Source]]
                [#assign albListenerId = formatALBListenerId(
                                                    tier,
                                                    component,
                                                    source)]
                [@output albListenerId /]
            [/#list]
            [#break]
    [/#switch]
[/#if]