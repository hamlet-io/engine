[#-- ECS --]

[#if componentType == "ecs"]
    [#list getOccurrences(tier, component) as occurrence ]

        [@cfDebug listMode occurrence false /]

        [#assign parentResources = occurrence.State.Resources]
        [#assign parentSolution = occurrence.Configuration.Solution ]

        [#assign ecsId = parentResources["cluster"].Id ]
        [#assign ecsSecurityGroupId = parentResources["securityGroup"].Id ]
        [#assign ecsServiceRoleId = parentResources["serviceRole"].Id ]
   
        [#assign networkLink = tier.Network.Link!{} ]

        [#assign networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]
        [#if ! networkLinkTarget?has_content ]
            [@cfException listMode "Network could not be found" networkLink /]
            [#break]
        [/#if]

        [#assign networkConfiguration = networkLinkTarget.Configuration.Solution]
        [#assign networkResources = networkLinkTarget.State.Resources ]

        [#assign routeTableLinkTarget = getLinkTarget(occurrence, networkLink + { "RouteTable" : tier.Network.RouteTable })]
        [#assign routeTableConfiguration = routeTableLinkTarget.Configuration.Solution ]
        [#assign publicRouteTable = routeTableConfiguration.Public ]

        [#assign vpcId = networkResources["vpc"].Id ]

        [#assign hibernate = parentSolution.Hibernate.Enabled &&
                                getExistingReference(ecsId)?has_content ]

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

            [#assign networkMode = solution.NetworkMode ]
            [#assign lbTargetType = "instance"]
            [#assign networkLinks = [] ]
            [#assign engine = solution.Engine?lower_case ]
            [#assign executionRoleId = ""]

            [#if engine == "fargate" && networkMode != "awsvpc" ]
                [@cfException
                    mode=listMode
                    description="Fargate containers only support the awsvpc network mode"
                    context=
                        {
                            "Description" : "Fargate containers only support the awsvpc network mode",
                            "NetworkMode" : networkMode
                        }
                /]
                [#break]
            [/#if]
            
            [#if networkMode == "awsvpc" ]
                        
                [#assign lbTargetType = "ip" ]

                [#assign ecsSecurityGroupId = resources["securityGroup"].Id ]
                [#assign ecsSecurityGroupName = resources["securityGroup"].Name ]

                [#assign subnets = multiAZ?then(
                    getSubnets(core.Tier, networkResources),
                    getSubnets(core.Tier, networkResources)[0..0]
                )]

                [#assign aswVpcNetworkConfiguration = 
                    {
                        "NetworkConfiguration" : {
                            "AwsvpcConfiguration" : {
                                "SecurityGroups" : getReferences(ecsSecurityGroupId),
                                "Subnets" : subnets,
                                "AssignPublicIp" : publicRouteTable?then("ENABLED", "DISABLED" )
                            }
                        }
                    }
                ]

                [#if deploymentSubsetRequired("ecs", true)]
                    [@createSecurityGroup
                        mode=listMode
                        tier=tier
                        component=component
                        id=ecsSecurityGroupId
                        name=ecsSecurityGroupName
                        vpcId=vpcId /]
                [/#if]
            [/#if] 

            [#if core.Type == ECS_SERVICE_COMPONENT_TYPE]

                [#assign serviceId = resources["service"].Id  ]
                [#assign serviceDependencies = []]

                [#if deploymentSubsetRequired("ecs", true)]

                    [#assign loadBalancers = [] ]
                    [#assign dependencies = [] ]
                    [#list containers as container]

                        [#-- allow local network comms between containers in the same service --]
                        [#if solution.ContainerNetworkLinks ]
                            [#if networkMode == "bridge" || engine != "fargate" ]
                                [#assign networkLinks += [ container.Name ] ]
                            [#else]
                                [@cfException
                                    mode=listMode
                                    description="Network links only avaialble on bridge mode and ec2 engine"
                                    context=
                                        {
                                            "Description" : "Container links are only available in bridge mode and ec2 engine",
                                            "NetworkMode" : networkMode
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

                                [#assign securityGroupCIDRs = getGroupCIDRs(sourceIPAddressGroups, true, subOccurrence)]
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

                    [#assign desiredCount = (solution.DesiredCount >= 0)?then(
                                solution.DesiredCount,
                                multiAZ?then(zones?size,1)
                            ) ]

                    [#if hibernate ]
                        [#assign desiredCount = 0 ]
                    [/#if]

                    [@createECSService
                        mode=listMode
                        id=serviceId
                        ecsId=ecsId
                        engine=engine
                        desiredCount=desiredCount
                        taskId=taskId
                        loadBalancers=loadBalancers
                        roleId=ecsServiceRoleId
                        networkMode=networkMode
                        networkConfiguration=aswVpcNetworkConfiguration!{}
                        placement=solution.Placement
                        dependencies=dependencies
                    /]
                [/#if]
            [/#if]

            [#assign dependencies = [] ]
            [#assign roleId = "" ]
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
            [/#if]

            [#assign executionRoleId = ""]
            [#if resources["executionRole"]?has_content ]
                [#assign executionRoleId = resources["executionRole"].Id]
                [#if deploymentSubsetRequired("iam", true ) && isPartOfCurrentDeploymentUnit(executionRoleId) ]
                    [@createRole
                        mode=listMode
                        id=executionRoleId
                        trustedServices=[
                            "ecs-tasks.amazonaws.com"
                        ]
                        managedArns=["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
                    /]
                [/#if]
            [/#if]

            [#if core.Type == ECS_TASK_COMPONENT_TYPE]
                [#if solution.Schedules?has_content ]

                    [#assign scheduleTaskRoleId = resources["scheduleRole"].Id ]

                    [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(scheduleTaskRoleId)]
                        [@createRole
                            mode=listMode
                            id=scheduleTaskRoleId
                            trustedServices=["events.amazonaws.com"]
                            policies=[
                                getPolicyDocument(
                                    ecsTaskRunPermission(ecsId) + 
                                    roleId?has_content?then(
                                        iamPassRolePermission(
                                            getReference(roleId, ARN_ATTRIBUTE_TYPE)
                                        ),
                                        []
                                    ) + 
                                    executionRoleId?has_content?then(
                                        iamPassRolePermission(
                                            getReference(executionRoleId, ARN_ATTRIBUTE_TYPE)
                                        ),
                                        []
                                    ),
                                    "schedule"
                                )
                            ]
                        /]
                    [/#if]

                    [#list solution.Schedules?values as schedule ]

                        [#assign scheduleRuleId = formatEventRuleId(subOccurrence, "schedule", schedule.Id) ]
                        [#assign scheduleEnabled = hibernate?then(
                                    false,
                                    schedule.Enabled
                        )]

                        [#if networkMode == "awsvpc" ]

                            [#-- Cloudfomation support not available for awsvpc network config which means that fargate isn't supported --]
                            [#assign eventRuleCliConfig = 
                                {
                                    "ScheduleExpression" : schedule.Expression,
                                    "State" : scheduleEnabled?then("ENABLED", "DISABLED")
                                }]

                            [#assign eventTargetCliConfig = 
                                {
                                    "Targets" : [  
                                        {
                                            "Id" : formatId(scheduleRuleId, "target"),
                                            "Arn" : getExistingReference(ecsId, ARN_ATTRIBUTE_TYPE),
                                            "EcsParameters" : {
                                                "TaskCount" : schedule.TaskCount
                                            } +
                                            attributeIfTrue(
                                                "NetworkConfiguration",
                                                networkMode = "awsvpc",
                                                {
                                                    "awsvpcConfiguration" : {
                                                        "Subnets" : subnets,
                                                        "AssignPublicIp" : publicRouteTable?then("ENABLE", "DISABLED")
                                                    }
                                                }
                                            ) +
                                            attributeIfTrue(
                                                "LaunchType",
                                                engine == "fargate",
                                                "FARGATE"
                                            )
                                        }
                                    ]
                                }]

                            [#assign ruleCliId = formatId(taskId, "rule")]
                            [#assign ruleCommand = "updateEventRule" ]
                            [#assign targetCliId = formatId(taskId, "target")]
                            [#assign targetCommand = "updateTargetRule" ]

                            [#if deploymentSubsetRequired("cli", false) ]
                                [@cfCli
                                    mode=listMode
                                    id=ruleCliId
                                    command=ruleCommand
                                    content=eventRuleCliConfig
                                /]

                                [@cfCli
                                    mode=listMode
                                    id=targetCliId
                                    command=targetCommand
                                    content=eventTargetCliConfig
                                /]
                            [/#if]

                            [#if deploymentSubsetRequired("epilogue", false)]

                                [#assign targetParameters = {
                                    "Arn" : getExistingReference(ecsId, ARN_ATTRIBUTE_TYPE),
                                    "Id" : taskId,
                                    "EcsParameters" : {
                                        "TaskCount" : schedule.TaskCount,
                                        "TaskDefinitionArn" : getReference(taskId, ARN_ATTRIBUTE_TYPE)
                                    },
                                    "RoleArn" : getReference(scheduleTaskRoleId, ARN_ATTRIBUTE_TYPE)
                                }]

                                [@cfScript 
                                    mode=listMode
                                    content=
                                        [
                                            " case $\{STACK_OPERATION} in",
                                            "   create|update)",
                                            "       # Get cli config file",
                                            "       split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?", 
                                            "       # Manage Scheduled Event",
                                            "       info \"Creating Scheduled Task...\"",
                                            "       create_ecs_scheduled_task" +
                                            "       \"" + region + "\" " + 
                                            "       \"" + scheduleRuleId + "\" " +
                                            "       \"$\{tmpdir}/cli-" + ruleCliId + "-" + ruleCommand + ".json\" " +
                                            "       \"$\{tmpdir}/cli-" + targetCliId + "-" + targetCommand + ".json\" " +
                                            "       \"$\{STACK_NAME}\" " +
                                            "       \"" + taskId + "\" " +
                                            "       \"" + (getExistingReference(scheduleTaskRoleId, ARN_ATTRIBUTE_TYPE)?has_content?then(
                                                                getExistingReference(scheduleTaskRoleId, ARN_ATTRIBUTE_TYPE),
                                                                scheduleTaskRoleId)) + "\" " + 
                                            "       \"" + ecsSecurityGroupId + "\" " + 
                                            "       || return $?",
                                            "       ;;",
                                            " esac"
                                        ]
                                /]
                            [/#if]

                            [#if deploymentSubsetRequired("prologue", false)]
                                [@cfScript 
                                    mode=listMode
                                    content=
                                        [
                                            " case $\{STACK_OPERATION} in",
                                            "   delete)",
                                            "       # Manage Scheduled Event",
                                            "       info \"Deleting Scheduled Task...\"",
                                            "       delete_cloudwatch_event" +
                                            "       \"" + region + "\" " + 
                                            "       \"" + scheduleRuleId + "\" " +
                                            "       \"true\" || return $?",
                                            "       ;;",
                                            " esac"
                                        ]
                                /]
                            [/#if]
                            
                        [#else]
                            [#if deploymentSubsetRequired("ecs", true) ]
                                [@createScheduleEventRule
                                    mode=listMode
                                    id=scheduleRuleId
                                    enabled=scheduleEnabled
                                    scheduleExpression=schedule.Expression
                                    targetParameters=targetParameters
                                    dependencies=fnId
                                /]
                            [/#if]
                        [/#if]
                    [/#list]
                [/#if]
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
                                    severity=alert.Severity
                                    resourceName=core.FullName
                                    alertName=alert.Name
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
                                    dimensions=getResourceMetricDimensions(monitoredResource, ( resources + { "cluster" : parentResources["cluster"] } ) )
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
                    engine=engine
                    containers=containers
                    role=roleId
                    executionRole=executionRoleId
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

