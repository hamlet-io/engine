[#if component.ECS??]
    [#assign ecs = component.ECS]
    [#assign fixedIP = ecs.FixedIP?? && ecs.FixedIP]
    [#assign ecsSG = getKey("securityGroup", componentIdStem) ]

    [#assign serviceInstances=[] ]
    [#if ecs.Services??]
        [#list ecs.Services?values as service]
            [#if deploymentRequired(service, deploymentUnit)]
                [#if service.Versions??]
                    [#list service.Versions?values as version]
                        [#if deploymentRequired(version, deploymentUnit)]
                            [#if version.Instances??]
                                [#list version.Instances?values as serviceInstance]
                                    [#if deploymentRequired(serviceInstance, deploymentUnit)]
                                        [#assign serviceInstances += [serviceInstance +
                                            {
                                                "Internal" : {
                                                    "ServiceId" : service.Id,
                                                    "ServiceName" : service.Name,
                                                    "VersionId" : version.Id,
                                                    "VersionName" : version.Name,
                                                    "InstanceId" : (serviceInstance.Id == "default")?string("",serviceInstance.Id),
                                                    "InstanceName" : (serviceInstance.Id == "default")?string("",serviceInstance.Name)
                                                }
                                            }
                                        ] ]
                                    [/#if]
                                [/#list]
                            [#else]
                                [#assign serviceInstances += [version +
                                    {
                                        "Internal" : {
                                            "ServiceId" : service.Id,
                                            "ServiceName" : service.Name,
                                            "VersionId" : version.Id,
                                            "VersionName" : version.Name,
                                            "InstanceId" : "",
                                            "InstanceName" : ""
                                        }
                                    }
                                ] ]
                            [/#if]
                        [/#if]
                    [/#list]
                [#else]
                    [#assign serviceInstances += [service +
                        {
                            "Internal" : {
                                "ServiceId" : service.Id,
                                "ServiceName" : service.Name,
                                "VersionId" : "",
                                "VersionName" : "",
                                "InstanceId" : "",
                                "InstanceName" : ""
                            }
                        }
                    ]]
                [/#if]
            [/#if]
        [/#list]
    [/#if]

    [#assign taskInstances=[] ]
    [#if ecs.Tasks??]
        [#list ecs.Tasks?values as task]
            [#if deploymentRequired(task, deploymentUnit)]
                [#if task.Versions??]
                    [#list task.Versions?values as version]
                        [#if deploymentRequired(version, deploymentUnit)]
                            [#if version.Instances??]
                                [#list version.Instances?values as taskInstance]
                                    [#if deploymentRequired(taskInstance, deploymentUnit)]
                                        [#assign taskInstances += [taskInstance +
                                            {
                                                "Internal" : {
                                                    "TaskId" : task.Id,
                                                    "TaskName" : task.Name,
                                                    "VersionId" : version.Id,
                                                    "VersionName" : version.Name,
                                                    "InstanceId" : (taskInstance.Id == "default")?string("",taskInstance.Id),
                                                    "InstanceName" : (taskInstance.Id == "default")?string("",taskInstance.Name)
                                                }
                                            }
                                        ] ]
                                    [/#if]
                                [/#list]
                            [#else]
                                [#assign taskInstances += [version +
                                    {
                                        "Internal" : {
                                            "TaskId" : task.Id,
                                            "TaskName" : task.Name,
                                            "VersionId" : version.Id,
                                            "VersionName" : version.Name,
                                            "InstanceId" : "",
                                            "InstanceName" : ""
                                        }
                                    }
                                ] ]
                            [/#if]
                        [/#if]
                    [/#list]
                [#else]
                    [#assign taskInstances += [task +
                        {
                            "Internal" : {
                                "TaskId" : task.Id,
                                "TaskName" : task.Name,
                                "VersionId" : "",
                                "VersionName" : "",
                                "InstanceId" : "",
                                "InstanceName" : ""
                            }
                        }
                    ]]
                [/#if]
            [/#if]
        [/#list]
    [/#if]

    [#list serviceInstances as serviceInstance]
        [#assign serviceDependencies = []]
        [#assign serviceIdStem = formatId(componentIdStem,
                                            serviceInstance.Internal.ServiceId,
                                            serviceInstance.Internal.VersionId,
                                            serviceInstance.Internal.InstanceId)]
        [#assign containerIdStem = formatName(serviceInstance.Internal.VersionId,
                                            serviceInstance.Internal.InstanceId)]
        [#if resourceCount > 0],[/#if]
        [#switch applicationListMode]
            [#case "definition"]
                [@createTask tier component serviceInstance serviceIdStem containerIdStem /],
                "${formatId("ecsService", serviceIdStem)}" : {
                    "Type" : "AWS::ECS::Service",
                    "Properties" : {
                        "Cluster" : [@reference getReference("ecs", componentIdStem) /],
                        "DeploymentConfiguration" : {
                            [#if multiAZ]
                                "MaximumPercent" : 100,
                                "MinimumHealthyPercent" : 50
                            [#else]
                                "MaximumPercent" : 100,
                                "MinimumHealthyPercent" : 0
                            [/#if]
                        },
                        [#if serviceInstance.DesiredCount??]
                            "DesiredCount" : "${serviceInstance.DesiredCount}",
                        [#else]
                            "DesiredCount" : "${multiAZ?string(zones?size,"1")}",
                        [/#if]
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
                                                        [#assign targetGroup = lb.TargetGroup!serviceInstance.Internal.VersionName]
                                                        [#if targetGroup != ""]
                                                            [#assign targetGroupKey = formatId("tg", lbTier.Id, lbComponent.Id, ports[lbPort].Port?c, targetGroup)]
                                                            [#if getKey(targetGroupKey)??]
                                                                "TargetGroupArn" : "${getKey(targetGroupKey)}",
                                                            [#else]
                                                                "TargetGroupArn" : { "Ref" : "${targetGroupKey}" },
                                                                [#assign serviceDependencies += [formatId("listenerRule", lbTier.Id, lbComponent.Id, ports[lbPort].Port?c, targetGroup)]]
                                                            [/#if]
                                                        [#else]
                                                            "LoadBalancerName" : "${getKey("elb", lbTier.Id, lbComponent.Id)}",
                                                        [/#if]
                                                    [#else]
                                                        "LoadBalancerName" : "${getKey("elb", "elb", port.ELB)}",
                                                    [/#if]
                                                    "ContainerName" : "${formatName(tier.Name, component.Name, container.Name) }",
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
                            "Role" : "${getKey("role", componentIdStem, "service")}",
                        [/#if]
                        "TaskDefinition" : { "Ref" : "${formatId("ecsTask", serviceIdStem)}" }
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
                [#break]

            [#case "outputs"]
                "${formatId("ecsService", serviceIdStem)}" : {
                    "Value" : { "Ref" : "${formatId("ecsService", serviceIdStem)}" }
                },
                "${formatId("ecsTask", serviceIdStem)}" : {
                    "Value" : { "Ref" : "${formatId("ecsTask", serviceIdStem)}" }
                }
                [#break]

        [/#switch]
                            
        [#list serviceInstance.Containers?values as container]
            [#if container?is_hash]
                [#switch applicationListMode]
                    [#case "definition"]
                        [#-- Supplemental definitions for the container --]
                        [#assign containerListMode = "supplemental"]
                        [#assign containerId = formatName(container.Id, containerIdStem)]
                        [#include containerList?ensure_starts_with("/")]
                        [#break]

                [/#switch]
                
                [#if container.Ports??]
                    [#list container.Ports?values as port]
                        [#if port?is_hash]
                            [#assign useDynamicHostPort = port.DynamicHostPort?? && port.DynamicHostPort]
                            [#if useDynamicHostPort]
                                [#assign portRange = "dynamic"]
                            [#else]
                                [#assign portRange = ports[port.Id].Port?c]
                            [/#if]

                            [#assign fromSG = (port.ELB?? || port.LB??) &&
                                (((port.LB.fromSGOnly)?? && port.LB.fromSGOnly) || fixedIP)]

                            [#if fromSG]
                                [#if port.ELB??]
                                    [#assign elbSG = getKey("securityGroup","elb", port.ELB)]
                                [#else]
                                    [#assign elbSG = getKey("securityGroup", port.LB.Tier, port.LB.Component)]
                                [/#if]
                            [/#if]

                            [#switch applicationListMode]
                                [#case "definition"]
                                    [#-- Security Group ingress for the container ports --]
                                    ,"${formatId("securityGroupIngress", serviceIdStem, container.Id, portRange)}" : {
                                        "Type" : "AWS::EC2::SecurityGroupIngress",
                                        "Properties" : {
                                            "GroupId": "${ecsSG}",
                                            "IpProtocol": "${ports[port.Id].IPProtocol}",
                                            [#if useDynamicHostPort]
                                                "FromPort": "32768",
                                                "ToPort": "65535",
                                            [#else]
                                                "FromPort": "${ports[port.Id].Port?c}",
                                                "ToPort": "${ports[port.Id].Port?c}",
                                            [/#if]
                                            [#if fromSG]
                                                "SourceSecurityGroupId": "${elbSG}"
                                            [#else]
                                                "CidrIp": "0.0.0.0/0"
                                            [/#if]
                                        }
                                    }
                                    [#break]
                            [/#switch]
                            
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
                                [#assign targetGroup = lb.TargetGroup!serviceInstance.Internal.VersionName]
                                [#if targetGroup != ""]
                                    [#assign targetGroupKey = formatId("tg", lbTier.Id, lbComponent.Id, ports[lbPort].Port?c, targetGroup)]
                                    [#if ! getKey(targetGroupKey)??]
                                        [#switch applicationListMode]
                                            [#case "definition"]
                                                ,[@createTargetGroup tier=lbTier component=lbComponent source=ports[lbPort] destination=ports[port.Id] name=targetGroup /]
                                                ,"${formatId("listenerRule", lbTier.Id, lbComponent.Id, ports[lbPort].Port?c, targetGroup)}" : {
                                                    "DependsOn" : [
                                                        "${targetGroupKey}"
                                                    ],
                                                    "Type" : "AWS::ElasticLoadBalancingV2::ListenerRule",
                                                    "Properties" : {
                                                        "Priority" : ${lb.Priority},
                                                        "Actions" : [
                                                            {
                                                                "Type": "forward",
                                                                "TargetGroupArn": { "Ref": "${targetGroupKey}" }
                                                            }
                                                        ],
                                                        "Conditions": [
                                                            {
                                                                "Field": "path-pattern",
                                                                "Values": [ "${lb.Path!serviceInstance.Internal.VersionName}" ]
                                                            }
                                                        ],
                                                        "ListenerArn" : "${getKey("listener", lbTier.Id, lbComponent.Id, ports[lbPort].Port?c)}"
                                                    }
                                                }
                                                [#break]

                                            [#case "outputs"]
                                                ,"${targetGroupKey}" : {
                                                    "Value" : { "Ref" : "${targetGroupKey}" }
                                                }
                                                [#break]

                                        [/#switch]
                                    [/#if]
                                [/#if]
                            [/#if]
                        [/#if]
                    [/#list]
                [/#if]
            [/#if]
        [/#list]
        [#assign resourceCount += 1]
    [/#list]

    [#list taskInstances as taskInstance]
        [#assign taskIdStem = formatId(componentIdStem,
                                            taskInstance.Internal.TaskId,
                                            taskInstance.Internal.VersionId,
                                            taskInstance.Internal.InstanceId)]
        [#assign containerIdStem = formatName(taskInstance.Internal.VersionId,
                                            taskInstance.Internal.InstanceId)]
        [#if resourceCount > 0],[/#if]
        [#switch applicationListMode]
            [#case "definition"]
                [@createTask tier component taskInstance taskIdStem containerIdStem /]
                [#list taskInstance.Containers?values as container]
                    [#if container?is_hash]
                        [#assign containerListMode = "supplemental"]
                        [#assign containerId = formatName(container.Id, containerIdStem)]
                        [#include containerList?ensure_starts_with("/")]
                    [/#if]
                [/#list]
                [#break]

            [#case "outputs"]
                "${formatId("ecsTask", taskIdStem)}" : {
                    "Value" : { "Ref" : "${formatId("ecsTask", taskIdStem)}" }
                }
            [#break]

        [/#switch]
        [#assign resourceCount += 1]
    [/#list]
[/#if]
