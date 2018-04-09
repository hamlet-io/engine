[#-- ELB --]

[#if componentType == ELB_COMPONENT_TYPE ]

    [#list requiredOccurrences(
        getOccurrences(tier, component),
        deploymentUnit) as occurrence]
    
         
        [@cfDebug listMode occurrence false /]
        [#assign core = occurrence.Core]
        [#assign configuration = occurrence.Configuration]
        [#assign resources = occurrence.State.Resources]

        [#assign elbId              = resources["lb"].Id]
        [#assign elbFullName        = resources["lb"].Name]
        [#assign elbShortFullName   = resources["lb"].ShortName]
        [#assign securityGroupId    = resources["sg"].Id]
        
        [#assign healthCheckDestination = ports[portMappings[configuration.PortMappings[0]].Destination] ]
        
        [#if deploymentSubsetRequired("elb", true)]
            [@createComponentSecurityGroup
                mode=listMode
                tier=tier
                component=component /]

            [#assign listeners = [] ]
            
            [#list configuration.PortMappings as mapping]
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
                        }  +
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
                                ":" + destination.Port?c + (configuration.HealthCheck.Path)!healthCheckDestination.HealthCheck.Path,
                            "HealthyThreshold" : (configuration.HealthCheck.HealthyThreshold)!destination.HealthCheck.HealthyThreshold,
                            "UnhealthyThreshold" : (configuration.HealthCheck.UnhealthyThreshold)!destination.HealthCheck.UnhealthyThreshold,
                            "Interval" : (configuration.HealthCheck.Interval)!destination.HealthCheck.Interval,
                            "Timeout" : (configuration.HealthCheck.Timeout)!destination.HealthCheck.Timeout
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
                    (configuration.Logs)?then(
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
    [/#list]
[/#if]