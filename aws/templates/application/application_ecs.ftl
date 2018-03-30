[#if componentType == "ecs"]
    [#list getOccurrences(tier, component) as occurrence ]

        [@cfDebug listMode occurrence false /]

        [#assign resources = occurrence.State.Resources]
        [#assign ecsId = resources["cluster"].Id!"" ]
        [#assign ecsSecurityGroupId = resources["securityGroup"].Id!"" ]
        [#assign ecsServiceRoleId = resources["serviceRole"].Id!"" ]

        [#list requiredOccurrences(
                occurrence.Occurrences![],
                deploymentUnit) as subOccurrence]

            [@cfDebug listMode subOccurrence false /]

            [#assign core = subOccurrence.Core ]
            [#assign solution = subOccurrence.Configuration.Solution ]
            [#assign resources = subOccurrence.State.Resources]

            [#assign taskId = resources["task"].Id ]
            [#assign containers = getTaskContainers(subOccurrence) ]

            [#if core.Type == SERVICE_COMPONENT_TYPE]
        
                [#assign serviceId = resources["service"].Id  ]
                [#assign serviceDependencies = []]
                
                [#if deploymentSubsetRequired("ecs", true)]
               
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
                            (solution.DesiredCount >= 0)?then(
                                solution.DesiredCount,
                                multiAZ?then(zones?size,1)
                            )
                        taskId=taskId
                        loadBalancers=loadBalancers
                        roleId=ecsServiceRoleId
                        dependencies=dependencies
                    /]
                [/#if]
            [/#if]
    
            [#assign dependencies = [] ]
    
            [#if solution.UseTaskRole]
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
    
                        [#assign linkPolicies = getLinkTargetsOutboundRoles(container.Links) ]
    
                        [#if linkPolicies?has_content]
                            [#assign policyId = formatDependentPolicyId(taskId, container.Id, "links")]
                            [@createPolicy
                                mode=listMode
                                id=policyId
                                name="links"
                                statements=linkPolicies
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
                [#list (solution.Containers!{})?values as container]
                    [#assign containerListMode = listMode]
                    [#assign containerId = formatContainerFragmentId(occurrence, container)]
                    [#include containerList?ensure_starts_with("/")]
                [/#list]
            [/#if]
        [/#list]
    [/#list]
[/#if]

