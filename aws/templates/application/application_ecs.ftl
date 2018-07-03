[#-- ECS --]

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
            [#assign taskName = resources["task"].Name ]
            [#assign containers = getTaskContainers(occurrence, subOccurrence) ]

            [#assign networkMode = (solution.NetworkMode)!"" ]
            [#assign lbTargetType = "instance"]

            [#if networkMode == "awsvpc" ]
                        
                [#assign subnets = multiAZ?then(
                    getSubnets(tier),
                    getSubnets(tier)[0..0]
                )]

                [#assign lbTargetType = "ip" ]

                [#assign ecsSecurityGroupId = resources["securityGroup"].Id ]
                [#assign ecsSecurityGroupName = resources["securityGroup"].Name ]

            [/#if] 

            [#if core.Type == ECS_SERVICE_COMPONENT_TYPE]

                [#assign serviceId = resources["service"].Id  ]
                [#assign serviceDependencies = []]

                [#if deploymentSubsetRequired("ecs", true)]

                    [#if networkMode == "awsvpc" ]
                        [@createSecurityGroup
                            mode=listMode
                            tier=tier
                            component=component
                            id=ecsSecurityGroupId
                            name=ecsSecurityGroupName /]
                    [/#if]

                    [#assign loadBalancers = [] ]
                    [#assign dependencies = [] ]
                    [#list containers as container]
                        [#list container.PortMappings![] as portMapping]
                            [#if portMapping.LoadBalancer?has_content]
                                [#assign loadBalancer = portMapping.LoadBalancer]
                                [#assign link = container.Links[loadBalancer.Link] ]
                                [@cfDebug listMode link false /]
                                [#assign linkCore = link.Core ]
                                [#assign linkResources = link.State.Resources ]
                                [#assign linkConfiguration = link.Configuration.Solution ]
                                [#assign linkAttributes = link.State.Attributes ]
                                [#assign targetId = "" ]
                                [#switch linkCore.Type]

                                    [#case LB_PORT_COMPONENT_TYPE]

                                        [#assign securityGroupSources = linkResources["sg"].Id  ]

                                        [#switch linkAttributes["ENGINE"] ] 
                                            [#case "network" ]
                                                [#assign securityGroupSources = linkConfiguration.IPAddressGroups + [ "_localnet" ] ]

                                            [#case "application" ]
                                                [#assign targetId = (linkResources["targetgroups"][loadBalancer.TargetGroup].Id)!"" ]
                                                [#if !targetId?has_content]
                                                    [#assign targetId = formatALBTargetGroupId(link, loadBalancer.TargetGroup) ]

                                                    [#if isPartOfCurrentDeploymentUnit(targetId)]

                                                        [@createTargetGroup
                                                            mode=listMode
                                                            id=targetId
                                                            name=formatName(linkCore.FullName,loadBalancer.TargetGroup)
                                                            tier=linkCore.Tier
                                                            component=linkCore.Component
                                                            destination=ports[portMapping.HostPort]
                                                            targetType=lbTargetType
                                                            /]

                                                        [#assign listenerRuleId = formatALBListenerRuleId(link, loadBalancer.TargetGroup) ]
                                                        [@createListenerRule
                                                            mode=listMode
                                                            id=listenerRuleId
                                                            listenerId=linkResources["listener"].Id
                                                            actions=getListenerRuleForwardAction(targetId)
                                                            conditions=getListenerRulePathCondition(loadBalancer.Path)
                                                            priority=loadBalancer.Priority!100
                                                            dependencies=targetId
                                                        /]
                                                        [#assign dependencies += [listenerRuleId] ]
                                                    [/#if]
                                                [/#if]

                                                [#assign loadBalancers +=
                                                    [
                                                        {
                                                            "ContainerName" : container.Name,
                                                            "ContainerPort" : ports[portMapping.ContainerPort].Port,
                                                            "TargetGroupArn" : getReference(targetId, ARN_ATTRIBUTE_TYPE)
                                                        }
                                                    ]
                                                ]
                                                [#break]
                                                
                                            [#case "classic"]

                                                [#if networkMode == "awsvpc" ]
                                                    [@cfException
                                                        mode=listMode
                                                        description="Network mode not compatible with LB"
                                                        context=
                                                            {
                                                                "Description" : "The current container network mode is not compatible with this load balancer engine",
                                                                "NetworkMode" : networkMode,
                                                                "LBEngine" : linkAttributes["ENGINE"]
                                                            }
                                                    /]
                                                [/#if]

                                                [#assign lbId =  linkAttributes["LB"] ]
                                                [#-- Classic ELB's register the instance so we only need 1 registration --]
                                                [#-- TODO: Change back to += when AWS allows multiple load balancer registrations per container --]
                                                [#assign loadBalancers =
                                                    [
                                                        {
                                                            "ContainerName" : container.Name,
                                                            "ContainerPort" : ports[portMapping.ContainerPort].Port,
                                                            "LoadBalancerName" : getExistingReference(lbId)
                                                        }
                                                    ]
                                                ]
                                            
                                                [#break]
                                        [/#switch]
                                    [#break]
                                [/#switch]

                                [#assign dependencies += [targetId] ]

                                [#if securityGroupSources?is_enumerable ]
                                    
                                    [#assign securityGroupCIDRs = getGroupCIDRs(securityGroupSources)]
                                    [#list securityGroupCIDRs as source ]
                                        
                                        [@createSecurityGroupIngress
                                            mode=listMode
                                            id=
                                                formatContainerSecurityGroupIngressId(
                                                    ecsSecurityGroupId,
                                                    container,
                                                    portMapping.DynamicHostPort?then(
                                                        "dynamic",
                                                        ports[portMapping.HostPort].Port
                                                    ),
                                                    replaceAlphaNumericOnly(source)
                                                )
                                            port=portMapping.DynamicHostPort?then(0, portMapping.HostPort)
                                            cidr=source
                                            groupId=ecsSecurityGroupId
                                    /]
                                    [/#list]
                                [#else]
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
                                        cidr=securityGroupSources
                                        groupId=ecsSecurityGroupId
                                    /]
                                [/#if]  
                                
                            [/#if]  
                        [/#list]
                        [#if container.IngressRules?has_content ]
                            [#list container.IngressRules as ingressRule ]
                                [@createSecurityGroupIngress
                                        mode=listMode
                                        id=formatContainerSecurityGroupIngressId(
                                                ecsSecurityGroupId,
                                                container,
                                                ingressRule.port,
                                                replaceAlphaNumericOnly(ingressRule.cidr)
                                            )
                                        port=ingressRule.port
                                        cidr=ingressRule.cidr
                                        groupId=ecsSecurityGroupId
                                    /]
                            [/#list]
                        [/#if]
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
                        networkMode=networkMode
                        subnets=subnets![]
                        securityGroups=getReferences(ecsSecurityGroupId)![]
                        dependencies=dependencies
                    /]
                [/#if]
            [/#if]

            [#assign dependencies = [] ]

            [#if solution.UseTaskRole]
                [#assign roleId = resources["taskrole"].Id ]
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

            [#if deploymentSubsetRequired("lg", true) ]
                [#if solution.TaskLogGroup ]
                    [#assign lgId = resources["lg"].Id ]
                    [#if isPartOfCurrentDeploymentUnit(lgId) ]
                        [@createLogGroup
                            mode=listMode
                            id=lgId
                            name=resources["lg"].Name /]
                    [/#if]
                [/#if]
                [#list containers as container]
                    [#if container.LogGroup?has_content]
                        [#assign lgId = container.LogGroup.Id ]
                        [#if isPartOfCurrentDeploymentUnit(lgId) ]
                            [@createLogGroup
                                mode=listMode
                                id=lgId
                                name=container.LogGroup.Name /]
                        [/#if]
                    [/#if]
                [/#list]
            [/#if]


            [#if deploymentSubsetRequired("ecs", true) ]

                [@createECSTask
                    mode=listMode
                    id=taskId
                    name=taskName
                    containers=containers
                    role=roleId
                    networkMode=networkMode
                    dependencies=dependencies
                    fixedName=solution.FixedName
                /]

            [/#if]
            
            [#if deploymentSubsetRequired("ecs", true)]

                [#-- Pick any extra macros in the container fragments --]
                [#list (solution.Containers!{})?values as container]
                    [#assign containerListMode = listMode]
                    [#assign containerId = formatContainerFragmentId(occurrence, container)]
                    [#include containerList?ensure_starts_with("/")]
                [/#list]

            [/#if]

            [#if deploymentSubsetRequired("prologue", false)]
                [#-- Copy any asFiles needed by the task --]
                [#assign asFiles = getAsFileSettings(subOccurrence.Configuration.Settings.Product) ]
                [#if asFiles?has_content]
                    [@cfDebug listMode asFiles false /]
                    [@cfScript
                        mode=listMode
                        content=
                            findAsFilesScript("filesToSync", asFiles) +
                            syncFilesToBucketScript(
                                "filesToSync",
                                regionId,
                                operationsBucket,
                                getOccurrenceSettingValue(subOccurrence, "SETTINGS_PREFIX")
                            ) /]
                [/#if]
            [/#if]
       [/#list]
    [/#list]
[/#if]

