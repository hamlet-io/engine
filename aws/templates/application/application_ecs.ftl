[#if componentType == "ecs"]
    [#assign ecs = component.ECS]
    [#assign fixedIP = ecs.FixedIP?? && ecs.FixedIP]
    [#assign ecsId = formatECSId(tier, component)]
    [#assign ecsSecurityGroupId = formatECSSecurityGroupId(tier, component)]
    [#assign ecsServiceRoleId = formatECSServiceRoleId(tier, component)]

    [#assign serviceOccurrences=[] ]
    [#list (ecs.Services!{})?values as service]
        [#assign serviceOccurrences += getOccurrences(service, deploymentUnit, "service") ]
    [/#list]
    
    [#assign taskOccurrences=[] ]
    [#list (ecs.Tasks!{})?values as task]
        [#assign taskOccurrences += getOccurrences(service, deploymentUnit, "task") ]
    [/#list]

    [#list serviceOccurrences as occurrence]
        [#assign serviceDependencies = []]
        [#assign serviceId = formatECSServiceId(
                                tier,
                                component,
                                occurrence)]
    [/#list]
    
    [#list (serviceOccurrences + taskOccurrences) as occurrence]
        [#assign taskId    = formatECSTaskId(
                                tier,
                                component,
                                occurrence)]
                                
        [#assign containers = getTaskContainers(tier, component, occurrence) ]

        [#if occurrence.UseTaskRole]
            [#assign roleId = formatDependentRoleId(taskId) ]
            [#if deploymentSubsetRequired("iam") && isPartOfCurrentDeploymentUnit(roleId)]
                [@createRole 
                    mode=applicationListMode
                    id=roleId
                    trustedServices=["ecs-tasks.amazonaws.com"]
                /]
                
                [#list containers as container]
                    [#if container.Policy?has_content]
                        [@createPolicy
                            mode=applicationListMode
                            id=formatDependentPolicyId(taskId, container.Id)]
                            name=container.Name
                            statements=container.Policy
                            role=roleId
                        /]
                    [/#if]
                [/#list]
            [/#if]
        [#else]
            [#assign roleId = "" ]
        [/#if]

        [#if deploymentSubsetRequired("ecs", true)]
            [@createECSTask
                mode=applicationListMode
                id=taskId
                containers=containers
                role=roleId
            /]
            
            [#list occurrence.Containers as container]
                [#assign containerListMode = applicationListMode]
                [#assign containerId = formatContainerFragmentId(occurrence, container)]
                [#include containerList]
            [/#list]
        [/#if]
    [/#list]
    
            getcomponent serviceInstance deploymentSubsetRequired("iam") /]
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
                                                mode=applicationListMode
                                                id=targetGroupId
                                                name=targetGroup
                                                tier=lbTier
                                                component=lbComponent
                                                source=ports[lbPort]
                                                destination=ports[port.Id]
                                            /]
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
