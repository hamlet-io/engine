[#if componentType == "ecs"]
    [#assign ecs = component.ECS]
    [#assign fixedIP = ecs.FixedIP?? && ecs.FixedIP]
    [#assign ecsId = formatECSId(tier, component)]
    [#assign ecsSecurityGroupId = formatECSSecurityGroupId(tier, component)]
    [#assign ecsServiceRoleId = formatECSServiceRoleId(tier, component)]

    [#assign serviceOccurrences=[] ]
    [#list (ecs.Services!{})?values as service]
        [#if service?is_hash]
            [#assign serviceOccurrences += getOccurrences(service, deploymentUnit, "service") ]
        [/#if]
    [/#list]

    [#assign taskOccurrences=[] ]
    [#list (ecs.Tasks!{})?values as task]
        [#if task?is_hash]
            [#assign taskOccurrences += getOccurrences(service, deploymentUnit, "task") ]
        [/#if]
    [/#list]

    [#list serviceOccurrences as occurrence]
        [#assign serviceDependencies = []]
        [#assign serviceId = formatECSServiceId(
                                tier,
                                component,
                                occurrence)]
        [#assign taskId    = formatECSTaskId(
                                tier,
                                component,
                                occurrence)]
        
        [#if deploymentSubsetRequired("ecs", true)]

            [#assign containers = getTaskContainers(tier, component, occurrence) ]

            [#assign loadBalancers = [] ]
            [#assign dependencies = [] ]
            [#list containers as container]
                [#list container.PortMappings![] as portMapping]
                    [#if portMapping.LoadBalancer?has_content]
                        [#assign loadBalancer = portMapping.LoadBalancer]
                        [#assign loadBalancerId = 
                            loadBalancer.TargetGroup?has_content?then(
                                formatALBTargetGroupId(
                                    loadBalancer.Tier,
                                    loadBalancer.Component,
                                    ports[loadBalancer.Port],
                                    loadBalancer.TargetGroup,
                                    loadBalancer.Instance,
                                    loadBalancer.Version
                                ),
                                formatELBId(
                                    loadBalancer.Tier,
                                    loadBalancer.Component,
                                    loadBalancer.Instance,
                                    loadBalancer.Version
                                )
                            )
                        ]
                        [#assign loadBalancers +=
                            [
                                {
                                    "ContainerName" : container.Name,
                                    "ContainerPort" : ports[portMapping.ContainerPort].Port
                                } +
                                loadBalancer.TargetGroup?has_content?then(
                                    {
                                        "TargetGroupArn" :
                                            getReference(loadBalancerId, ARN_ATTRIBUTE_TYPE)
                                    },
                                    {
                                        "LoadBalancerName" :
                                            getReference(loadBalancerId)
                                    }
                                )
                            ]
                        ]
                        [#assign dependencies += [loadBalancerId] ]

                        [#assign loadBalancerSecurityGroupId = 
                                    formatComponentSecurityGroupId(
                                        loadBalancer.Tier,
                                        loadBalancer.Component,
                                        loadBalancer.Instance,
                                        loadBalancer.Version) ]
                                        
                        [@createSecurityGroupIngress
                            mode=listMode
                            id=
                                formatContainerSecurityGroupIngressId(
                                    ecsSecurityGroupId,
                                    container,
                                    portMapping.DynamicHostPort?then(
                                        "dynamic",
                                        ports[portMapping.HostPort].Port
                                    )
                                )
                            port=portMapping.DynamicHostPort?then(0, portMapping.HostPort)
                            cidr="0.0.0.0/0"
                            groupId=ecsSecurityGroupId
                        /]

                        [#if (loadBalancer.TargetGroup?has_content) &&
                                isPartOfCurrentDeploymentUnit(loadBalancerId)]

                            [@createTargetGroup
                                mode=listMode
                                id=loadBalancerId
                                name=loadBalancer.TargetGroup
                                tier=loadBalancer.Tier
                                component=loadBalancer.Component
                                source=ports[loadBalancer.Port]
                                destination=ports[portMapping.HostPort]
                            /]
                            [#assign listenerRuleId = 
                                formatALBListenerRuleId(
                                    loadBalancer.Tier,
                                    loadBalancer.Component,
                                    ports[loadBalancer.Port],
                                    loadBalancer.TargetGroup,
                                    loadBalancer.Instance,
                                    loadBalancer.Version
                                )]
                            [@createListenerRule
                                mode=listMode
                                id=listenerRuleId
                                listenerId=
                                    formatALBListenerId(
                                        loadBalancer.Tier,
                                        loadBalancer.Component,
                                        ports[loadBalancer.Port],
                                        loadBalancer.Instance,
                                        loadBalancer.Version
                                    )
                                actions=getListenerRuleForwardAction(loadBalancerId)
                                conditions=getListenerRulePathCondition(loadBalancer.Path)
                                priority=loadBalancer.Priority!100
                                dependencies=loadBalancerId
                            /]
                        [#assign dependencies += [listenerRuleId] ]
                        [/#if]    
                    [/#if]
                [/#list]
            [/#list]

            [@createECSService
                mode=listMode
                id=serviceId
                ecsId=ecsId
                desiredCount=
                    (occurrence.DesiredCount >= 0)?then(
                        occurrence.DesiredCount,
                        multiAZ?then(zones?size,1)
                    )
                taskId=taskId
                loadBalancers=loadBalancers
                roleId=ecsServiceRoleId
                dependencies=dependencies
            /]
        [/#if]
    [/#list]
    
    [#list (serviceOccurrences + taskOccurrences) as occurrence]
        [#assign taskId    = formatECSTaskId(
                                tier,
                                component,
                                occurrence)]
                                
        [#assign containers = getTaskContainers(tier, component, occurrence) ]

        [#assign dependencies = [] ]

        [#if occurrence.UseTaskRole]
            [#assign roleId = formatDependentRoleId(taskId) ]
            [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(roleId)]
                [@createRole 
                    mode=listMode
                    id=roleId
                    trustedServices=["ecs-tasks.amazonaws.com"]
                /]
                
                [#list containers as container]
                    [#if container.Policy?has_content]
                        [#assign policyId = formatDependentPolicyId(taskId, container.Id) ]
                        [@createPolicy
                            mode=listMode
                            id=policyId
                            name=container.Name
                            statements=container.Policy
                            roles=roleId
                        /]
                        [#assign dependencies += [policyId] ]
                    [/#if]
                [/#list]
            [/#if]
        [#else]
            [#assign roleId = "" ]
        [/#if]

        [#if deploymentSubsetRequired("ecs", true)]
            [@createECSTask
                mode=listMode
                id=taskId
                containers=containers
                role=roleId
                dependencies=dependencies
            /]

            [#-- Pick any extra macros in the container fragments --]
            [#list (occurrence.Containers!{})?values as container]
                [#assign containerListMode = listMode]
                [#assign containerId = formatContainerFragmentId(occurrence, container)]
                [#include containerList?ensure_starts_with("/")]
            [/#list]
        [/#if]
    [/#list]
[/#if]

