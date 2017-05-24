[#if componentType == "ecs"]
    [#assign ecs = component.ECS]
    [#assign fixedIP = ecs.FixedIP?? && ecs.FixedIP]
    [#assign ecsId = 
                formatECSId(
                    tier,
                    component)]
    [#assign ecsSecurityGroupId =
                formatECSSecurityGroupId(
                    tier,
                    component)]
    [#assign ecsServiceRoleId = 
                formatECSServiceRoleId(
                    tier,
                    component)]

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
                                                    "IdExtensions" : [
                                                        getTaskId(service),
                                                        version.Id,
                                                        (serviceInstance.Id == "default")?
                                                            string(
                                                                "",
                                                                serviceInstance.Id)],
                                                    "HostIdExtensions" : [
                                                        version.Id,
                                                        (serviceInstance.Id == "default")?
                                                            string(
                                                                "",
                                                                serviceInstance.Id)],
                                                    "StageName" : version.Id,
                                                    "DesiredCount" : serviceInstance.DesiredCount!
                                                                        version.DesiredCount!
                                                                        service.DesiredCount!-1
                                                }
                                            }
                                        ] ]
                                    [/#if]
                                [/#list]
                            [#else]
                                [#assign serviceInstances += [version +
                                    {
                                        "Internal" : {
                                            "IdExtensions" : [
                                                getTaskId(service),
                                                version.Id],
                                            "HostIdExtensions" : [
                                                version.Id],
                                            "StageName" : version.Id,
                                            "DesiredCount" : version.DesiredCount!
                                                                service.DesiredCount!-1
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
                                "IdExtensions" : [
                                    getTaskId(service)],
                                "HostIdExtensions" : [],
                                "StageName" : "",
                                "DesiredCount" : service.DesiredCount!-1
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
                                                    "IdExtensions" : [
                                                        getTaskId(task),
                                                        version.Id,
                                                        (taskInstance.Id == "default")?
                                                            string(
                                                                "",
                                                                taskInstance.Id)],
                                                   "HostIdExtensions" : [
                                                        version.Id,
                                                        (taskInstance.Id == "default")?
                                                            string(
                                                                "",
                                                                taskInstance.Id)],
                                                    "StageName" : version.Id
                                                }
                                            }
                                        ] ]
                                    [/#if]
                                [/#list]
                            [#else]
                                [#assign taskInstances += [version +
                                    {
                                        "Internal" : {
                                            "IdExtensions" : [
                                                getTaskId(task),
                                                version.Id],
                                            "HostIdExtensions" : [
                                                version.Id],
                                            "StageName" : version.Id
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
                                "IdExtensions" : [
                                    getTaskId(task)],
                                "HostIdExtensions" : [],
                                "StageName" : ""
                            }
                        }
                    ]]
                [/#if]
            [/#if]
        [/#list]
    [/#if]

    [#list serviceInstances as serviceInstance]
        [#assign serviceDependencies = []]
        [#assign serviceId = formatECSServiceId(
                                tier,
                                component,
                                serviceInstance)]
        [#assign taskId    = formatECSTaskId(
                                tier,
                                component,
                                serviceInstance)]
        [#if resourceCount > 0],[/#if]
        [#switch applicationListMode]
            [#case "definition"]
                [@createTask tier component serviceInstance /],
                "${serviceId}" : {
                    "Type" : "AWS::ECS::Service",
                    "Properties" : {
                        "Cluster" : "${getKey(ecsId)}",
                        "DeploymentConfiguration" : {
                            [#if multiAZ]
                                "MaximumPercent" : 100,
                                "MinimumHealthyPercent" : 50
                            [#else]
                                "MaximumPercent" : 100,
                                "MinimumHealthyPercent" : 0
                            [/#if]
                        },
                        [#if serviceInstance.DesiredCount > 0 ]
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
                                                        [#assign targetGroup = lb.TargetGroup!serviceInstance.Internal.StageName]
                                                        [#if targetGroup != ""]
                                                            [#assign targetGroupId = formatALBTargetGroupId(
                                                                                        lbTier,
                                                                                        lbComponent,
                                                                                        ports[lbPort],
                                                                                        targetGroup)]
                                                            "TargetGroupArn" : [@createReference targetGroupId /],
                                                            [#if !(getKey(targetGroupId)?has_content)]
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
                [#break]

            [#case "outputs"]
                [@output serviceId /],
                [@output taskId /]
                [#break]

        [/#switch]
                            
        [#list serviceInstance.Containers?values as container]
            [#if container?is_hash]
                [#switch applicationListMode]
                    [#case "definition"]
                        [#-- Supplemental definitions for the container --]
                        [#assign containerListMode = "supplemental"]
                        [#assign containerId = formatContainerId(
                                                serviceInstance,
                                                container)]
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
                                    [#assign elbSG = getKey(formatComponentSecurityGroupId(
                                                              getTier("elb"), 
                                                              getComponent("elb", port.ELB)))]
                                [#else]
                                    [#assign elbSG = getKey(formatComponentSecurityGroupId(
                                                              getTier(port.LB.Tier), 
                                                              getComponent(port.LB.Tier, port.LB.Component)))]
                                [/#if]
                            [/#if]

                            [#switch applicationListMode]
                                [#case "definition"]
                                    [#-- Security Group ingress for the container ports --]
                                    ,"${formatContainerSecurityGroupIngressId(
                                            ecsSecurityGroupId,
                                            container,
                                            portRange)}" : {
                                        "Type" : "AWS::EC2::SecurityGroupIngress",
                                        "Properties" : {
                                            "GroupId": "${getKey(ecsSecurityGroupId)}",
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
                                [#assign targetGroup = lb.TargetGroup!serviceInstance.Internal.StageName]
                                [#if targetGroup != ""]
                                    [#assign targetGroupId = formatALBTargetGroupId(
                                                                lbTier,
                                                                lbComponent,
                                                                ports[lbPort],
                                                                targetGroup)]
                                    [#if ! getKey(targetGroupId)?has_content]
                                        [#switch applicationListMode]
                                            [#case "definition"]
                                                ,[@createTargetGroup
                                                    lbTier
                                                    lbComponent
                                                    ports[lbPort]
                                                    ports[port.Id]
                                                    targetGroup /]
                                                ,"${formatALBListenerRuleId(
                                                        lbTier,
                                                        lbComponent,
                                                        ports[lbPort],
                                                        targetGroup)}" : {
                                                    "DependsOn" : [
                                                        "${targetGroupId}"
                                                    ],
                                                    "Type" : "AWS::ElasticLoadBalancingV2::ListenerRule",
                                                    "Properties" : {
                                                        "Priority" : ${lb.Priority},
                                                        "Actions" : [
                                                            {
                                                                "Type": "forward",
                                                                "TargetGroupArn": { "Ref": "${targetGroupId}" }
                                                            }
                                                        ],
                                                        "Conditions": [
                                                            {
                                                                "Field": "path-pattern",
                                                                "Values": [ "${lb.Path!"/" + serviceInstance.Internal.StageName + "/*"}" ]
                                                            }
                                                        ],
                                                        "ListenerArn" : "${getKey(formatALBListenerId(
                                                                                    lbTier,
                                                                                    lbComponent,
                                                                                    ports[lbPort]))}"
                                                    }
                                                }
                                                [#break]

                                            [#case "outputs"]
                                                ,[@output targetGroupId /]
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
        [#assign taskId = formatECSTaskId(
                                    tier,
                                    component,
                                    taskInstance)]
        [#if resourceCount > 0],[/#if]
        [#switch applicationListMode]
            [#case "definition"]
                [@createTask tier component taskInstance /]
                [#list taskInstance.Containers?values as container]
                    [#if container?is_hash]
                        [#assign containerListMode = "supplemental"]
                        [#assign containerId = formatContainerId(
                                                taskInstance,
                                                container)]
                        [#include containerList?ensure_starts_with("/")]
                    [/#if]
                [/#list]
                [#break]

            [#case "outputs"]
                [@output taskId /]
            [#break]

        [/#switch]
        [#assign resourceCount += 1]
    [/#list]
[/#if]
