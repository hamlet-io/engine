[#-- ECS --]
[#if component.ECS??]
    [#assign ecs = component.ECS]
    [#switch applicationListMode]
        [#case "definition"]
            [#assign fixedIP = ecs.FixedIP?? && ecs.FixedIP]
            [#assign ecsSG = getKey("securityGroupX" + tier.Id + "X" + component.Id) ]
            [#if ecs.Services??]
                [#list ecs.Services?values as service]
                    [#assign serviceDependencies = []]
                    [#if service?is_hash && (service.Slices!component.Slices)?seq_contains(slice)]
                        [#if resourceCount > 0],[/#if]
                        [@createTask tier=tier component=component task=service /],
                        "ecsServiceX${tier.Id}X${component.Id}X${service.Id}" : {
                            "Type" : "AWS::ECS::Service",
                            "Properties" : {
                                "Cluster" : "${getKey("ecsX" + tier.Id + "X" + component.Id)}",
                                "DeploymentConfiguration" : {
                                    [#if multiAZ]
                                        "MaximumPercent" : 100,
                                        "MinimumHealthyPercent" : 50
                                    [#else]
                                        "MaximumPercent" : 100,
                                        "MinimumHealthyPercent" : 0
                                    [/#if]
                                },
                                [#if service.DesiredCount??]
                                    "DesiredCount" : "${service.DesiredCount}",
                                [#else]
                                    "DesiredCount" : "${multiAZ?string(zones?size,"1")}",
                                [/#if]
                                [#assign portCount = 0]
                                [#list service.Containers?values as container]
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
                                        [#list service.Containers?values as container]
                                            [#if container?is_hash && container.Ports??]
                                                [#list container.Ports?values as port]
                                                    [#if port?is_hash && (port.ELB?? || port.LB??)]
                                                        [#if portCount > 0],[/#if]
                                                        {
                                                            [#if port.LB??]
                                                                [#assign lb = port.LB]
                                                                [#assign lbPort = port.Id]
                                                                [#if lb.PortMapping??]
                                                                    [#assign lbPort = portMappings[lb.PortMapping].Source]
                                                                [/#if]
                                                                [#if lb.Port??]
                                                                    [#assign lbPort = lb.Port]
                                                                [/#if]
                                                                [#if lb.TargetGroup??]
                                                                    [#assign targetGroupKey = "tgX" + lb.Tier + "X" + lb.Component + "X" + ports[lbPort].Port?c + "X" + lb.TargetGroup]
                                                                    [#if getKey(targetGroupKey)??]
                                                                        "TargetGroupArn" : "${getKey(targetGroupKey)}",
                                                                    [#else]
                                                                        "TargetGroupArn" : { "Ref" : "${targetGroupKey}" },
                                                                        [#assign serviceDependencies += ["listenerRuleX${lb.Tier}X${lb.Component}X${ports[lbPort].Port?c}X${lb.TargetGroup}"]]
                                                                    [/#if]
                                                                [#else]
                                                                    "LoadBalancerName" : "${getKey("elbX" + port.lb.Tier + "X" + port.lb.Component)}",
                                                                [/#if]
                                                            [#else]
                                                                "LoadBalancerName" : "${getKey("elbXelbX" + port.ELB)}",
                                                            [/#if]
                                                            "ContainerName" : "${tier.Name + "-" + component.Name + "-" + container.Name}",
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
                                    "Role" : "${getKey("roleX" + tier.Id + "X" + component.Id + "Xservice")}",
                                [/#if]
                                "TaskDefinition" : { "Ref" : "ecsTaskX${tier.Id}X${component.Id}X${service.Id}" }
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
                        [#assign containerListMode = "supplemental"]
                        [#list service.Containers?values as container]
                            [#if container?is_hash]
                                [#-- Supplemental definitions for the container --]
                                [#include "/" + containerList]

                                [#-- Security Group ingress for the container ports --]
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
                                                    [#assign elbSG = getKey("securityGroupXelbX" + port.ELB)]
                                                [#else]
                                                    [#assign elbSG = getKey("securityGroupX" + port.lb.Tier + "X" + port.lb.Component)]
                                                [/#if]
                                            [/#if]
                                            ,"securityGroupIngressX${tier.Id}X${component.Id}X${service.Id}X${container.Id}X${portRange}" : {
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
                                                [#if lb.TargetGroup??]
                                                    [#assign targetGroupKey = "tgX" + lbTier.Id + "X" + lbComponent.Id + "X" + ports[lbPort].Port?c + "X" + lb.TargetGroup]
                                                    [#if ! getKey(targetGroupKey)??]
                                                        ,[@createTargetGroup tier=lbTier component=lbComponent source=ports[lbPort] destination=ports[port.Id] name=lb.TargetGroup /]
                                                        ,"listenerRuleX${lbTier.Id}X${lbComponent.Id}X${ports[lbPort].Port?c}X${lb.TargetGroup}" : {
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
                                                                        "Values": [ "${lb.Path}" ]
                                                                    }
                                                                ],
                                                                "ListenerArn" : "${getKey("listenerX" + lbTier.Id + "X" +  lbComponent.Id + "X" + ports[lbPort].Port?c)}"
                                                            }
                                                        }
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
                    [#if task?is_hash && (task.Slices!component.Slices)?seq_contains(slice)]
                        [#if resourceCount > 0],[/#if]
                        [@createTask tier=tier component=component task=task /]
                        [#assign containerListMode = "supplemental"]
                        [#list task.Containers?values as container]
                            [#if container?is_hash]
                                [#include "/"+containerList]
                            [/#if]
                        [/#list]
                        [#assign resourceCount += 1]
                    [/#if]
                [/#list]
            [/#if]
            [#break]

        [#case "outputs"]
            [#if ecs.Services??]
                [#list ecs.Services?values as service]
                    [#assign serviceDependencies = []]
                    [#if service?is_hash && (service.Slices!component.Slices)?seq_contains(slice)]
                            [#if resourceCount > 0],[/#if]
                            "ecsServiceX${tier.Id}X${component.Id}X${service.Id}" : {
                                "Value" : { "Ref" : "ecsServiceX${tier.Id}X${component.Id}X${service.Id}" }
                            },
                            "ecsTaskX${tier.Id}X${component.Id}X${service.Id}" : {
                                "Value" : { "Ref" : "ecsTaskX${tier.Id}X${component.Id}X${service.Id}" }
                            }
                            [#list service.Containers?values as container]
                                [#if container?is_hash && container.Ports??]
                                    [#list container.Ports?values as port]
                                        [#if port?is_hash && port.LB??]
                                            [#assign lb = port.LB]
                                            [#assign lbPort = port.Id]
                                            [#if lb.PortMapping??]
                                                [#assign lbPort = portMappings[lb.PortMapping].Source]
                                            [/#if]
                                            [#if lb.Port??]
                                                [#assign lbPort = lb.Port]
                                            [/#if]
                                            [#if lb.TargetGroup??]
                                                [#assign targetGroupKey = "tgX" + lb.Tier + "X" + lb.Component + "X" + ports[lbPort].Port?c + "X" + lb.TargetGroup]
                                                [#if ! getKey(targetGroupKey)??]
                                                    ,"${targetGroupKey}" : {
                                                        "Value" : { "Ref" : "${targetGroupKey}" }
                                                    }
                                                [/#if]
                                            [/#if]
                                        [/#if]
                                    [/#list]
                                [/#if]
                            [/#list]
                            [#assign resourceCount += 1]
                    [/#if]
                [/#list]
            [/#if]
            [#if ecs.Tasks??]
                [#list ecs.Tasks?values as task]
                    [#if task?is_hash && (task.Slices!component.Slices)?seq_contains(slice)]
                        [#if resourceCount > 0],[/#if]
                            "ecsTaskX${tier.Id}X${component.Id}X${task.Id}" : {
                                "Value" : { "Ref" : "ecsTaskX${tier.Id}X${component.Id}X${task.Id}" }
                            }
                            [#assign resourceCount += 1]
                    [/#if]
                [/#list]
            [/#if]
            [#break]

    [/#switch]
[/#if]