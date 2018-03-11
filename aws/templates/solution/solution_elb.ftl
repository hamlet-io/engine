[#-- ELB --]
[#if (componentType == "elb") && deploymentSubsetRequired("elb", true)]
    [#assign elb = component.ELB]

    [#assign elbId = formatELBId(tier, component)]
    [#assign elbFullName = formatComponentFullName(tier, component) ]
    [#assign elbShortFullName = formatComponentShortFullName(tier, component)]
    [#assign securityGroupId = formatComponentSecurityGroupId(tier, component) ]
    [#assign healthCheckDestination = ports[portMappings[elb.PortMappings[0]].Destination] ]

    [@createComponentSecurityGroup
        mode=listMode
        tier=tier
        component=component /]

    [#assign listeners = [] ]
    [#list elb.PortMappings as mapping]
        [#assign source = ports[portMappings[mapping].Source]]
        [#assign destination = ports[portMappings[mapping].Destination]]
        
        [@createSecurityGroupIngress
            mode=listMode
            id=formatComponentSecurityGroupIngressId(tier, component,source.Port)
            port=source.Port
            cidr="0.0.0.0/0"
            groupId=securityGroupId
        /]
        [#assign listeners +=
            [
                {
                    "LoadBalancerPort" : source.Port,
                    "Protocol" : source.Protocol,
                    "InstancePort" : destination.Port,
                    "InstanceProtocol" : destination.Protocol
                } +
                attributeIfTrue(
                    "SSLCertificateId",
                    source.Certificate!false,
                    getExistingReference(formatCertificateId(certificateId))?has_content?then(
                        getExistingReference(formatCertificateId(certificateId)),
                        {
                            "Fn::Join" : [
                                "",
                                [
                                    "arn:aws:iam::",
                                    {"Ref" : "AWS::AccountId"},
                                    ":server-certificate/ssl/"
                                    certificateId,
                                    "/",
                                    certificateId,
                                    "-ssl"
                                ]
                            ]
                        }
                    ))
            ]
        ]
    [/#list]

    [@cfResource
        mode=listMode
        id=elbId
        type="AWS::ElasticLoadBalancing::LoadBalancer"
        properties=
            {
                "Listeners" : listeners,
                "HealthCheck" : {
                    "Target" :
                        (healthCheckDestination.HealthCheck.Protocol)!(healthCheckDestination.Protocol) + 
                        ":" + destination.Port?c + (elb.HealthCheck.Path)!healthCheckDestination.HealthCheck.Path,
                    "HealthyThreshold" : (elb.HealthCheck.HealthyThreshold)!destination.HealthCheck.HealthyThreshold,
                    "UnhealthyThreshold" : (elb.HealthCheck.UnhealthyThreshold)!destination.HealthCheck.UnhealthyThreshold,
                    "Interval" : (elb.HealthCheck.Interval)!destination.HealthCheck.Interval,
                    "Timeout" : (elb.HealthCheck.Timeout)!destination.HealthCheck.Timeout
                },
                "Scheme" :
                    (tier.Network.RouteTable == "external")?then(
                        "internet-facing",
                        "internal"
                    ),
                "SecurityGroups":[ getReference(securityGroupId) ],
                "LoadBalancerName" : elbShortFullName
            } +
            multiAZ?then(
                {
                    "Subnets" : getSubnets(tier),
                    "CrossZone" : true
                },
                {
                    "Subnets" : getSubnets(tier)[0]
                }
            ) +
            ((elb.Logs)!false)?then(
                {
                    "AccessLoggingPolicy" : {
                        "EmitInterval" : 5,
                        "Enabled" : true,
                        "S3BucketName" : operationsBucket
                    }
                },
                {}
            )
        tags=
            getCfTemplateCoreTags(
                elbFullName,
                tier,
                component)
        outputs=ELB_OUTPUT_MAPPINGS
    /]
[/#if]