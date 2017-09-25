[#-- ECS --]

[#macro createECSTask mode id containers role=""]

    [#local definitions = [] ]
    [#local volumes = [] ]
    [#list containers as container]
        [#local mountPoints = [] ]
        [#list (container.Volumes!{}) as name,volume]
            [#local mountPoints +=
                [
                    {
                        "ContainerPath" : volume.ContainerPath,
                        "SourceVolume" : name,
                        "ReadOnly" : volume.ReadOnly
                    }
                ]
            ]
            [#local volumes +=
                [
                    {
                        "Name" : name
                    } +
                    volume.HostPath?has_content?then(
                        {
                            "Host" : {
                                "SourcePath" : volume.HostPath
                            }
                        },
                        {}
                    )
                ]
            ]
        [/#list]
        [#local portMappings = [] ]
        [#list (container.PortMappings!{}) as portMapping]
            [#local portMappings +=
                [
                    {
                        "ContainerPort" : portMapping.ContainerPort,
                        "HostPort" : portMapping.HostPort
                    }
                ]
            ]
        [/#list]
        [#local environment = [] ]
        [#list (container.Environment!{}) as name,value]
            [#local environment +=
                [
                    {
                        "Name" : name,
                        "Value" : value
                    }
                ]
            ]
        [/#list]
        [#local extraHosts = [] ]
        [#list (container.Hosts!{}) as name,value]
            [#local extraHosts +=
                [
                    {
                        "Hostname" : name,
                        "IpAddress" : value
                    }
                ]
            ]
        [/#list]
        [#local definitions +=
            {
                "Name" : container.Name,
                "Image : container.Image +
                            container.Version?has_content?then(
                                ":" + container.Version,
                                ""
                            ),
                "Essential" : container.Essential,
                "MemoryReservation" : container.Memory,
                "LogConfiguration" : 
                    {
                        "LogDriver" : container.LogDriver
                    } + 
                    container.LogOptions?has_content?then(
                        {
                            "Options" : container.LogOptions
                        },
                        {}
                    )
                }
            } +
            environment?has_content?then(
                {
                    "Environment" : environment
                },
                {}
            ) +
            mountPoints?has_content?then(
                {
                    "MountPoints" : mountPoints
                },
                {}
            ) +
            extraHosts?has_content?then(
                {
                    "ExtraHosts" : extraHosts
                },
                {}
            ) +
            container.MaximumMemory?has_content?then(
                {
                    "Memory" : container.MaximumMemory
                },
                {}
            ) +
            container.Cpu?has_content?then(
                {
                    "Cpu" : container.Cpu
                },
                {}
            ) +
            portMappings?has_content?then(
                {
                    "PortMappings" : portMappings
                },
                {}
            )
                
        ]
    [/#list]

    [@cfTemplate
        mode=mode
        id=id
        type="AWS::ECS::TaskDefinition"
        properties=
            {
                "ContainerDefinitions" : definitions
            } + 
            volumes?has_content?then(
                {
                    "Volumes" : volumes
                },
                {}
            ) +
            role?has_content?then(
                {
                    "TaskRoleArn" : getReference(role, ARN_ATTRIBUTE_TYPE)
                },
                {}
            )
    /]
[/#macro]

[#macro createECSService mode id containers ecsId ]

    [#local definitions = [] ]
    [#local volumes = [] ]
    [#list containers as container]
        [#local mountPoints = [] ]
        [#list (container.Volumes!{}) as name,volume]
            [#local mountPoints +=
                [
                    {
                        "ContainerPath" : volume.ContainerPath,
                        "SourceVolume" : name,
                        "ReadOnly" : volume.ReadOnly
                    }
                ]
            ]
            [#local volumes +=
                [
                    {
                        "Name" : name
                    } +
                    volume.HostPath?has_content?then(
                        {
                            "Host" : {
                                "SourcePath" : volume.HostPath
                            }
                        },
                        {}
                    )
                ]
            ]
        [/#list]
        [#local portMappings = [] ]
        [#list (container.PortMappings!{}) as portMapping]
            [#local portMappings +=
                [
                    {
                        "ContainerPort" : portMapping.ContainerPort,
                        "HostPort" : portMapping.HostPort
                    }
                ]
            ]
        [/#list]
        [#local environment = [] ]
        [#list (container.Environment!{}) as name,value]
            [#local environment +=
                [
                    {
                        "Name" : name,
                        "Value" : value
                    }
                ]
            ]
        [/#list]
        [#local extraHosts = [] ]
        [#list (container.Hosts!{}) as name,value]
            [#local extraHosts +=
                [
                    {
                        "Hostname" : name,
                        "IpAddress" : value
                    }
                ]
            ]
        [/#list]
        [#local definitions +=
            {
                "Name" : container.Name,
                "Image : container.Image +
                            container.Version?has_content?then(
                                ":" + container.Version,
                                ""
                            ),
                "Essential" : container.Essential,
                "MemoryReservation" : container.Memory,
                "LogConfiguration" : 
                    {
                        "LogDriver" : container.LogDriver
                    } + 
                    container.LogOptions?has_content?then(
                        {
                            "Options" : container.LogOptions
                        },
                        {}
                    )
                }
            } +
            environment?has_content?then(
                {
                    "Environment" : environment
                },
                {}
            ) +
            mountPoints?has_content?then(
                {
                    "MountPoints" : mountPoints
                },
                {}
            ) +
            extraHosts?has_content?then(
                {
                    "ExtraHosts" : extraHosts
                },
                {}
            ) +
            container.MaximumMemory?has_content?then(
                {
                    "Memory" : container.MaximumMemory
                },
                {}
            ) +
            container.Cpu?has_content?then(
                {
                    "Cpu" : container.Cpu
                },
                {}
            ) +
            portMappings?has_content?then(
                {
                    "PortMappings" : portMappings
                },
                {}
            )
                
        ]
    [/#list]

    [@cfTemplate
        mode=mode
        id=id
        type="AWS::ECS::Service"
        properties=
            {
                "Cluster" : getExistingReference(ecsId),
                "ContainerDefinitions" : definitions
            } + 
            volumes?has_content?then(
                {
                    "Volumes" : volumes
                },
                {}
            ) +
            role?has_content?then(
                {
                    "TaskRoleArn" : getReference(role, ARN_ATTRIBUTE_TYPE)
                },
                {}
            )
    /]
[/#macro]
                            [#if serviceInstance.Internal.DesiredCount > 0 ]
                                [#assign desiredCount = serviceInstance.Internal.DesiredCount ]
                            [#else]
                                [#assign desiredCount = multiAZ?then(zones?size,1)]
                            [/#if]
                            "DeploymentConfiguration" : {
                                [#if desiredCount > 1]
                                    "MaximumPercent" : 100,
                                    "MinimumHealthyPercent" : 50
                                [#else]
                                    "MaximumPercent" : 100,
                                    "MinimumHealthyPercent" : 0
                                [/#if]
                            },
                            "DesiredCount" : "${desiredCount}",
                            [#assign portCount = 0]
                            [#list serviceInstance.Containers?values as container]
                                [#if container?is_hash && container.Ports??]
                                    [#list container.Ports?values as port]
                                        [#if port?is_hash && (port.ELB?? || port.LB??)]
                                            [#assign portCount += 1]
                                            [#break]
                                        [/#if]
                                    [/#list]
                                [/#if]
                            [/#list]
                            [#if portCount != 0]
                                "LoadBalancers" : [
                                    [#assign portCount = 0]
                                    [#list serviceInstance.Containers?values as container]
                                        [#if container?is_hash && container.Ports??]
                                            [#list container.Ports?values as port]
                                                [#if port?is_hash && (port.ELB?? || port.LB??)]
                                                    [#if portCount > 0],[/#if]
                                                    {
                                                        [#if port.LB??]
                                                            [#assign lb = port.LB]
                                                            [#assign lbTier = getTier(lb.Tier)]
                                                            [#assign lbComponent = getComponent(lb.Tier, lb.Component)]
                                                            [#assign lbPort = port.Id]
                                                            [#if lb.PortMapping??]
                                                                [#assign lbPort = portMappings[lb.PortMapping].Source]
                                                            [/#if]
                                                            [#if lb.Port??]
                                                                [#assign lbPort = lb.Port]
                                                            [/#if]
                                                            [#assign targetGroup = lb.TargetGroup!serviceInstance.Internal.StageName]
                                                            [#if targetGroup != ""]
                                                                [#assign targetGroupId = formatALBTargetGroupId(
                                                                                            lbTier,
                                                                                            lbComponent,
                                                                                            ports[lbPort],
                                                                                            targetGroup)]
                                                                "TargetGroupArn" : [@createReference targetGroupId /],
                                                                [#if isPartOfCurrentDeploymentUnit(targetGroupId)]
                                                                    [#assign serviceDependencies += [formatALBListenerRuleId(
                                                                                                        lbTier,
                                                                                                        lbComponent,
                                                                                                        ports[lbPort],
                                                                                                        targetGroup)]]
                                                                [/#if]
                                                            [#else]
                                                                "LoadBalancerName" : "${getKey(formatALBId(
                                                                                                lbTier,
                                                                                                lbComponent))}",
                                                            [/#if]
                                                        [#else]
                                                            "LoadBalancerName" : "${getKey(formatELBId(
                                                                                            getTier("elb"),
                                                                                            getComponent("elb", port.ELB)))}",
                                                        [/#if]
                                                        "ContainerName" : "${formatContainerName(
                                                                                tier,
                                                                                component,
                                                                                serviceInstance,
                                                                                container) }",
                                                        [#if port.Container??]
                                                            "ContainerPort" : ${ports[port.Container].Port?c}
                                                        [#else]
                                                            "ContainerPort" : ${ports[port.Id].Port?c}
                                                        [/#if]
                                                    }
                                                    [#assign portCount += 1]
                                                [/#if]
                                            [/#list]
                                        [/#if]
                                    [/#list]
                                ],
                                "Role" : "${getKey(ecsServiceRoleId)}",
                            [/#if]
                            "TaskDefinition" : { "Ref" : "${taskId}" }
                        }
                        [#if serviceDependencies?size > 0 ]
                            ,"DependsOn" : [
                                [#list serviceDependencies as dependency]
                                    "${dependency}"
                                    [#if !(dependency == serviceDependencies?last)],[/#if]
                                [/#list]
                            ]
                        [/#if]
                    }
