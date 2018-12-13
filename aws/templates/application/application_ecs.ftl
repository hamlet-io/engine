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
            [#assign networkLinks = [] ]

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

                        [#-- allow local network comms between containers in the same service --]
                        [#if solution.ContainerNetworkLinks ]
                            [#if solution.NetworkMode == "bridge" ]
                                [#assign networkLinks += [ container.Name ] ]
                            [#else]
                                [@cfException
                                    mode=listMode
                                    description="Network links only avaialble on bridge mode"
                                    context=
                                        {
                                            "Description" : "Container links are only available in bridge mode",
                                            "NetworkMode" : solution.NetworkMode
                                        }
                                /]
                            [/#if]
                        [/#if]

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
                                
                                [#assign sourceSecurityGroupIds = []]
                                [#assign sourceIPAddressGroups = [] ]
                                
                                [#switch linkCore.Type]

                                    [#case LB_PORT_COMPONENT_TYPE]

                                        [#switch linkAttributes["ENGINE"] ] 
                                            [#case "application" ]
                                            [#case "classic"]
                                                [#assign sourceSecurityGroupIds += [ linkResources["sg"].Id ] ]
                                                [#break]
                                            [#case "network" ]
                                                [#assign sourceIPAddressGroups = linkConfiguration.IPAddressGroups + [ "_localnet" ] ]
                                                [#break]
                                        [/#switch]

                                        [#switch linkAttributes["ENGINE"] ] 
                                            [#case "network" ]
                                            [#case "application" ]
                                                [#assign loadBalancers +=
                                                    [
                                                        {
                                                            "ContainerName" : container.Name,
                                                            "ContainerPort" : ports[portMapping.ContainerPort].Port,
                                                            "TargetGroupArn" : linkAttributes["TARGET_GROUP_ARN"]
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

                                [#assign securityGroupCIDRs = getGroupCIDRs(sourceIPAddressGroups)]
                                [#list securityGroupCIDRs as cidr ]
                                    
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
                                                replaceAlphaNumericOnly(cidr)
                                            )
                                        port=portMapping.DynamicHostPort?then(0, portMapping.HostPort)
                                        cidr=cidr
                                        groupId=ecsSecurityGroupId
                                /]
                                [/#list]

                                [#list sourceSecurityGroupIds as group ]
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
                                        cidr=group
                                        groupId=ecsSecurityGroupId
                                    /]
                                [/#list]
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
                        placement=solution.Placement
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
                    [#assign managedPolicy = []]

                    [#list containers as container]
                        [#if container.ManagedPolicy?has_content ]
                            [#assign managedPolicy += container.ManagedPolicy ]
                        [/#if]

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

                    [@createRole
                        mode=listMode
                        id=roleId
                        trustedServices=["ecs-tasks.amazonaws.com"]
                        managedArns=managedPolicy
                    /]
                [/#if]
            [#else]
                [#assign roleId = "" ]
            [/#if]

            [#if deploymentSubsetRequired("lg", true) ]
                [#if solution.TaskLogGroup ]
                    [#assign lgId = resources["lg"].Id ]
                    [#assign lgName = resources["lg"].Name]
                    [#if isPartOfCurrentDeploymentUnit(lgId) ]
                        [@createLogGroup
                            mode=listMode
                            id=lgId
                            name=lgName /]
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

                [#list containers as container ]
                    [#if container.LogGroup?has_content && container.LogMetrics?has_content ]
                        [#list container.LogMetrics as name,logMetric ]

                            [#assign lgId = container.LogGroup.Id ]
                            [#assign lgName = container.LogGroup.Name ]

                            [#assign logMetricId = formatDependentLogMetricId(lgId, logMetric.Id)]

                            [#assign containerLogMetricName = getMetricName( 
                                    logMetric.Name, 
                                    AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE, 
                                    formatName(core.ShortFullName, container.Name) )]

                            [#assign logFilter = logFilters[logMetric.LogFilter].Pattern ]

                            [#assign resources += { 
                                "logMetrics" : resources.LogMetrics!{} + {
                                    "lgMetric" + name + container.Name : {
                                    "Id" : formatDependentLogMetricId( lgId, logMetric.Id ),
                                    "Name" : getMetricName( logMetric.Name, AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE, containerLogMetricName ),
                                    "Type" : AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE,
                                    "LogGroupName" : lgName,
                                    "LogGroupId" : lgId,
                                    "LogFilter" : logMetric.LogFilter
                                    }
                                }
                            }]

                        [/#list]
                    [/#if]
                [/#list]

                [#list resources.logMetrics as logMetricName,logMetric ]

                    [@createLogMetric
                        mode=listMode
                        id=logMetric.Id
                        name=logMetric.Name
                        logGroup=logMetric.LogGroupName
                        filter=logFilters[logMetric.LogFilter].Pattern
                        namespace=getResourceMetricNamespace(logMetric.Type)
                        value=1
                        dependencies=logMetric.LogGroupId
                    /]

                [/#list]

                [#list solution.Alerts?values as alert ]

                    [#assign monitoredResources = getMonitoredResources(resources, alert.Resource)]
                    [#list monitoredResources as name,monitoredResource ]

                        [#switch alert.Comparison ]
                            [#case "Threshold" ]
                                [@createCountAlarm
                                    mode=listMode
                                    id=formatDependentAlarmId(monitoredResource.Id, alert.Id )
                                    name=alert.Severity?upper_case + "-" + monitoredResource.Name!core.ShortFullName + "-" + alert.Name
                                    actions=[
                                        getReference(formatSegmentSNSTopicId())
                                    ]
                                    metric=getMetricName(alert.Metric, monitoredResource.Type, core.ShortFullName)
                                    namespace=getResourceMetricNamespace(monitoredResource.Type)
                                    description=alert.Description!alert.Name
                                    threshold=alert.Threshold
                                    statistic=alert.Statistic
                                    evaluationPeriods=alert.Periods
                                    period=alert.Time
                                    operator=alert.Operator
                                    reportOK=alert.ReportOk
                                    missingData=alert.MissingData
                                    dimensions=getResourceMetricDimensions(monitoredResource, resources)
                                    dependencies=monitoredResource.Id
                                /]
                            [#break]
                        [/#switch]
                    [/#list]
                [/#list]

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
                    [#assign fragmentListMode = listMode]
                    [#assign fragmentId = formatFragmentId(container, occurrence)]
                    [#assign containerId = fragmentId]
                    [#include fragmentList?ensure_starts_with("/")]
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

