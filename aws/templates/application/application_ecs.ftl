[#if component.ECS??]
    [#assign ecs = component.ECS]
    [#assign fixedIP = ecs.FixedIP?? && ecs.FixedIP]
    [#assign ecsSG = getKey("securityGroup", componentIdStem) ]
    [#if ecs.Services??]
        [#list ecs.Services?values as service]
            [#assign serviceFound = false]
            [#if service?is_hash]
                [#assign serviceIdStem = formatId(componentIdStem, service.Id)]
                [#assign serviceVersion = ""]
                [#assign serviceVersionName = ""]
                [#if service.Versions??]
                    [#list service.Versions?values as version]
                        [#if deploymentRequired(version, deploymentUnit)]
                            [#assign serviceFound = true]
                            [#assign serviceVersion = version.Id]
                            [#assign serviceVersionName = version.Name]
                            [#assign serviceIdStem = formatId(serviceIdStem, version.Id)]
                            [#assign serviceObject = version]
                            [#break]
                        [/#if]
                    [/#list]
                [#else]
                    [#if deploymentRequired(service, deploymentUnit) ]
                        [#assign serviceFound = true]
                        [#assign serviceObject = service]
                    [/#if]
                [/#if]
            [/#if]
            [#if serviceFound]
                [#assign serviceDependencies = []]
                [#if resourceCount > 0],[/#if]
                [#switch applicationListMode]
                    [#case "definition"]
                        [@createTask tier component serviceObject serviceIdStem serviceVersion /],
                        "${formatId("ecsService", serviceIdStem)}" : {
                            "Type" : "AWS::ECS::Service",
                            "Properties" : {
                                "Cluster" : "${getKey("ecs", componentIdStem)}",
                                "DeploymentConfiguration" : {
                                    [#if multiAZ]
                                        "MaximumPercent" : 100,
                                        "MinimumHealthyPercent" : 50
                                    [#else]
                                        "MaximumPercent" : 100,
                                        "MinimumHealthyPercent" : 0
                                    [/#if]
                                },
                                [#if serviceObject.DesiredCount??]
                                    "DesiredCount" : "${serviceObject.DesiredCount}",
                                [#else]
                                    "DesiredCount" : "${multiAZ?string(zones?size,"1")}",
                                [/#if]
                                [#assign portCount = 0]
                                [#list serviceObject.Containers?values as container]
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
                                        [#list serviceObject.Containers?values as container]
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
                                                                [#assign targetGroup = lb.TargetGroup!serviceVersionName]
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
                                
                [#list serviceObject.Containers?values as container]
                    [#if container?is_hash]
                        [#switch applicationListMode]
                            [#case "definition"]
                                [#-- Supplemental definitions for the container --]
                                [#assign containerListMode = "supplemental"]
                                [#assign containerId = formatName(container.Id, serviceVersion)]
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
                                            [#assign elbSG = getKey("securityGroup", port.lb.Tier, port.lb.Component)]
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
                                        [#assign targetGroup = lb.TargetGroup!serviceVersionName]
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
                                                                        "Values": [ "${lb.Path!serviceVersionName}" ]
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
            [/#if]
        [/#list]
    [/#if]

    [#if ecs.Tasks??]
        [#list ecs.Tasks?values as task]
            [#assign taskFound = false]
            [#if task?is_hash]
                [#assign taskIdStem = formatId(componentIdStem, task.Id)]
                [#assign taskVersion = ""]
                [#if task.Versions??]
                    [#list task.Versions?values as version]
                        [#if deploymentRequired(version, deploymentUnit)]
                            [#assign taskFound = true]
                            [#assign taskVersion = version.Id]
                            [#assign taskIdStem = formatId(taskIdStem, version.Id)]
                            [#assign taskObject = version]
                            [#break]
                        [/#if]
                    [/#list]
                [#else]
                    [#if deploymentRequired(task, deploymentUnit) ]
                        [#assign taskFound = true]
                        [#assign taskObject = task]
                    [/#if]
                [/#if]
            [/#if]
            [#if taskFound]
                [#if resourceCount > 0],[/#if]
                [#switch applicationListMode]
                    [#case "definition"]
                        [@createTask tier component taskObject taskIdStem taskVersion /],
                        [#list task.Containers?values as container]
                            [#if container?is_hash]
                                [#assign containerListMode = "supplemental"]
                                [#assign containerId = formatName(container.Id, taskVersion)]
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
            [/#if]
        [/#list]
    [/#if]
[/#if]
