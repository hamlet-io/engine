[#if componentType == "ecs"]
    [#assign ecs = component.ECS]
    [#assign fixedIP = ecs.FixedIP?? && ecs.FixedIP]
    [#assign ecsSG = getKey(formatComponentSecurityGroupResourceId(
                                tier,
                                component))]

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
                                                    "HostId" : service.Id,
                                                    "TaskId" : service.Id,
                                                    "TaskName" : service.Name,
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
                                            "HostId" : service.Id,
                                            "TaskId" : service.Id,
                                            "TaskName" : service.Name,
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
                                "HostId" : service.Id,
                                "TaskId" : service.Id,
                                "TaskName" : service.Name,
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
        [#assign serviceResourceId = formatECSServiceResourceId(
                                        tier,
                                        component,
                                        serviceInstance)]
        [#assign taskResourceId    = formatECSTaskResourceId(
                                        tier,
                                        component,
                                        serviceInstance)]
        [#if resourceCount > 0],[/#if]
        [#switch applicationListMode]
            [#case "definition"]
                [@createTask tier component serviceInstance /],
                "${serviceResourceId}" : {
                    "Type" : "AWS::ECS::Service",
                    "Properties" : {
                        "Cluster" : "${getKey(formatECSResourceId(
                                                tier,
                                                component))}",
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
                                                            [#assign targetGroupResourceId = formatALBTargetGroupResourceId(
                                                                                                lbTier,
                                                                                                lbComponent,
                                                                                                ports[lbPort],
                                                                                                targetGroup)]
                                                            "TargetGroupArn" : [@createReference targetGroupResourceId /],
                                                            [#if !(getKey(targetGroupResourceId)?has_content)]
                                                                [#assign serviceDependencies += [formatALBListenerRuleResourceId(
                                                                                                    lbTier,
                                                                                                    lbComponent,
                                                                                                    ports[lbPort],
                                                                                                    targetGroup)]]
                                                            [/#if]
                                                        [#else]
                                                            "LoadBalancerName" : "${getKey(formatALBResourceId(
                                                                                            lbTier,
                                                                                            lbComponent))}",
                                                        [/#if]
                                                    [#else]
                                                        "LoadBalancerName" : "${getKey(formatELBResourceId(
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
                            "Role" : "${getKey(formatECSServiceRoleResourceId(
                                                tier,
                                                component))}",
                        [/#if]
                        "TaskDefinition" : { "Ref" : "${taskResourceId}" }
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
                "${serviceResourceId}" : {
                    "Value" : { "Ref" : "${serviceResourceId}" }
                },
                "${taskResourceId}" : {
                    "Value" : { "Ref" : "${taskResourceId}" }
                }
                [#break]

        [/#switch]
                            
        [#list serviceInstance.Containers?values as container]
            [#if container?is_hash]
                [#switch applicationListMode]
                    [#case "definition"]
                        [#-- Supplemental definitions for the container --]
                        [#assign containerListMode = "supplemental"]
                        [#assign containerId = formatContainerId(
                                                tier,
                                                component,
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
                                    [#assign elbSG = getKey(formatComponentSecurityGroupResourceId(
                                                              getTier("elb"), 
                                                              getComponent("elb", port.ELB)))]
                                [#else]
                                    [#assign elbSG = getKey(formatComponentSecurityGroupResourceId(
                                                              getTier(port.LB.Tier), 
                                                              getComponent(port.LB.Tier, port.LB.Component)))]
                                [/#if]
                            [/#if]

                            [#switch applicationListMode]
                                [#case "definition"]
                                    [#-- Security Group ingress for the container ports --]
                                    ,"${formatContainerSecurityGroupIngressResourceId(
                                            tier,
                                            component,
                                            serviceInstance,
                                            container,
                                            portRange)}" : {
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
                                    [#assign targetGroupResourceId = formatALBTargetGroupResourceId(
                                                                        lbTier,
                                                                        lbComponent,
                                                                        ports[lbPort],
                                                                        targetGroup)]
                                    [#if ! getKey(targetGroupResourceId)?has_content]
                                        [#switch applicationListMode]
                                            [#case "definition"]
                                                ,[@createTargetGroup lbTier lbComponent ports[lbPort] ports[port.Id] targetGroup /]
                                                ,"${formatALBListenerRuleResourceId(
                                                        lbTier,
                                                        lbComponent,
                                                        ports[lbPort],
                                                        targetGroup)}" : {
                                                    "DependsOn" : [
                                                        "${targetGroupResourceId}"
                                                    ],
                                                    "Type" : "AWS::ElasticLoadBalancingV2::ListenerRule",
                                                    "Properties" : {
                                                        "Priority" : ${lb.Priority},
                                                        "Actions" : [
                                                            {
                                                                "Type": "forward",
                                                                "TargetGroupArn": { "Ref": "${targetGroupResourceId}" }
                                                            }
                                                        ],
                                                        "Conditions": [
                                                            {
                                                                "Field": "path-pattern",
                                                                "Values": [ "${lb.Path!"/" + serviceInstance.Internal.VersionName + "/*"}" ]
                                                            }
                                                        ],
                                                        "ListenerArn" : "${getKey(formatALBListenerResourceId(
                                                                                    lbTier,
                                                                                    lbComponent,
                                                                                    ports[lbPort]))}"
                                                    }
                                                }
                                                [#break]

                                            [#case "outputs"]
                                                ,"${targetGroupResourceId}" : {
                                                    "Value" : { "Ref" : "${targetGroupResourceId}" }
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
        [#assign taskResourceId = formatECSTaskResourceId(
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
                                                tier,
                                                component,
                                                taskInstance,
                                                container)]
                        [#include containerList?ensure_starts_with("/")]
                    [/#if]
                [/#list]
                [#break]

            [#case "outputs"]
                "${taskResourceId}" : {
                    "Value" : { "Ref" : "${taskResourceId}" }
                }
            [#break]

        [/#switch]
        [#assign resourceCount += 1]
    [/#list]
[/#if]
