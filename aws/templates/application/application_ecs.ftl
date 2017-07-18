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
                                                    "NameExtensions" : [
                                                        getTaskName(service),
                                                        version.Id,
                                                        (serviceInstance.Name == "default")?
                                                            string(
                                                                "",
                                                                serviceInstance.Name)],
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
                                            "NameExtensions" : [
                                                getTaskName(service),
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
                                "NameExtensions" : [
                                    getTaskName(service)],
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
                                                    "NameExtensions" : [
                                                        getTaskName(task),
                                                        version.Name,
                                                        (taskInstance.Name == "default")?
                                                            string(
                                                                "",
                                                                taskInstance.Name)],
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
                                            "NameExtensions" : [
                                                getTaskName(task),
                                                version.Name],
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
                                "NameExtensions" : [
                                    getTaskName(task)],
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

        [@createTask tier component serviceInstance deploymentSubsetRequired("iam") /]
        [#if deploymentSubsetRequired("ecs", true)]
            [#switch applicationListMode]
                [#case "definition"]
                    [@checkIfResourcesCreated /]
                    "${serviceId}" : {
                        "Type" : "AWS::ECS::Service",
                        "Properties" : {
                            "Cluster" : "${getKey(ecsId)}",
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
                    [@resourcesCreated /]
                    [#break]
    
                [#case "outputs"]
                    [@output serviceId /]
                    [#break]
    
            [/#switch]
                                
            [#-- Supplemental definitions for the containers --]
            [#switch applicationListMode]
                [#case "definition"]
                    [#assign containerListMode = "supplementalCount"]
                    [#assign supplementalCount = 0]
                    [#list serviceInstance.Containers?values as container]
                        [#if container?is_hash]
                            [#assign containerId = formatContainerId(
                                                    serviceInstance,
                                                    container)]
                            [#include containerList?ensure_starts_with("/")]
                        [/#if]
                    [/#list]
                
                    [#if (supplementalCount > 0)]
                        [@checkIfResourcesCreated /]
                        [#assign containerListMode = "supplemental"]
                        [#assign supplementalCount = 0]
                        [#list serviceInstance.Containers?values as container]
                            [#if container?is_hash]
                                [#assign containerId = formatContainerId(
                                                        serviceInstance,
                                                        container)]
                                [#include containerList?ensure_starts_with("/")]
                            [/#if]
                        [/#list]
                        [@resourcesCreated /]
                    [/#if]
                    [#break]
    
            [/#switch]
                    
            [#list serviceInstance.Containers?values as container]
                [#if container?is_hash]
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
                                        [@checkIfResourcesCreated /]
                                        [#-- Security Group ingress for the container ports --]
                                        "${formatContainerSecurityGroupIngressId(
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
                                        [@resourcesCreated /]
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
                                        [#if isPartOfCurrentDeploymentUnit(targetGroupId)]
                                            [@createTargetGroup
                                                applicationListMode
                                                lbTier
                                                lbComponent
                                                ports[lbPort]
                                                ports[port.Id]
                                                targetGroup /]
                                            [#switch applicationListMode]
                                                [#case "definition"]
                                                    [@checkIfResourcesCreated /]
                                                    "${formatALBListenerRuleId(
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
                                                    [@resourcesCreated /]
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
        [/#if]
    [/#list]

    [#list taskInstances as taskInstance]
        [@createTask tier component taskInstance deploymentSubsetRequired("iam")/]
        [#if deploymentSubsetRequired("ecs", true)]
            [#switch applicationListMode]
                [#case "definition"]
                    [#assign containerListMode = "supplementalCount"]
                    [#assign supplementalCount = 0]
                    [#list taskInstance.Containers?values as container]
                        [#if container?is_hash]
                            [#assign containerId = formatContainerId(
                                                    taskInstance,
                                                    container)]
                            [#include containerList?ensure_starts_with("/")]
                        [/#if]
                    [/#list]
                        
                    [#if (supplementalCount > 0)]
                        [@checkIfResourcesCreated /]
                        [#assign containerListMode = "supplemental"]
                        [#assign supplementalCount = 0]
                        [#list taskInstance.Containers?values as container]
                            [#if container?is_hash]
                                [#assign containerId = formatContainerId(
                                                        taskInstance,
                                                        container)]
                                [#include containerList?ensure_starts_with("/")]
                            [/#if]
                        [/#list]
                        [@resourcesCreated /]
                    [/#if]
                    [#break]
    
            [/#switch]
        [/#if]
    [/#list]
[/#if]
