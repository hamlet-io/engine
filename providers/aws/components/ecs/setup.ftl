[#ftl]
[#macro aws_ecs_cf_solution occurrence ]
    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["template"])
        /]
        [#return]
    [/#if]

    [@cfDebug listMode occurrence false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]

    [#local ecsId = resources["cluster"].Id ]
    [#local ecsName = resources["cluster"].Name ]
    [#local ecsRoleId = resources["role"].Id ]
    [#local ecsServiceRoleId = resources["serviceRole"].Id ]
    [#local ecsInstanceProfileId = resources["instanceProfile"].Id ]
    [#local ecsAutoScaleGroupId = resources["autoScaleGroup"].Id ]
    [#local ecsLaunchConfigId = resources["launchConfig"].Id ]
    [#local ecsSecurityGroupId = resources["securityGroup"].Id ]
    [#local ecsLogGroupId = resources["lg"].Id ]
    [#local ecsLogGroupName = resources["lg"].Name ]
    [#local ecsInstanceLogGroupId = resources["lgInstanceLog"].Id]
    [#local ecsInstanceLogGroupName = resources["lgInstanceLog"].Name]
    [#local defaultLogDriver = solution.LogDriver ]
    [#local fixedIP = solution.FixedIP ]

    [#local hibernate = solution.Hibernate.Enabled &&
                            getExistingReference(ecsId)?has_content ]

    [#local processorProfile = getProcessor(occurrence, "ECS")]
    [#local storageProfile = getStorage(occurrence, "ECS")]
    [#local logFileProfile = getLogFileProfile(occurrence, "ECS")]
    [#local bootstrapProfile = getBootstrapProfile(occurrence, "ECS")]

    [#-- Baseline component lookup --]
    [#local baselineComponentIds = getBaselineLinks(solution.Profiles.Baseline, [ "OpsData", "AppData", "Encryption", "SSHKey" ] )]

    [#local operationsBucket = getExistingReference(baselineComponentIds["OpsData"]) ]
    [#local dataBucket = getExistingReference(baselineComponentIds["AppData"])]
    [#local sshKeyPairId = baselineComponentIds["SSHKey"] ]

    [#local occurrenceNetwork = getOccurrenceNetwork(occurrence) ]
    [#local networkLink = occurrenceNetwork.Link!{} ]

    [#local networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]

    [#if ! networkLinkTarget?has_content ]
        [@cfException listMode "Network could not be found" networkLink /]
        [#return]
    [/#if]

    [#local networkConfiguration = networkLinkTarget.Configuration.Solution]
    [#local networkResources = networkLinkTarget.State.Resources ]

    [#local vpcId = networkResources["vpc"].Id ]

    [#local routeTableLinkTarget = getLinkTarget(occurrence, networkLink + { "RouteTable" : occurrenceNetwork.RouteTable })]
    [#local routeTableConfiguration = routeTableLinkTarget.Configuration.Solution ]
    [#local publicRouteTable = routeTableConfiguration.Public ]

    [#local ecsTags = getOccurrenceCoreTags(occurrence, ecsName, "", true)]

    [#local environmentVariables = {}]

    [#local configSetName = occurrence.Core.Type]
    [#local configSets =
            getInitConfigDirectories() +
            getInitConfigBootstrap(occurrence, operationsBucket, dataBucket) +
            getInitConfigECSAgent(ecsId, defaultLogDriver, solution.DockerUsers, solution.VolumeDrivers ) ]

    [#local efsMountPoints = {}]

    [#local fragment = getOccurrenceFragmentBase(occurrence) ]

    [#local contextLinks = getLinkTargets(occurrence) ]
    [#assign _context =
        {
            "Id" : fragment,
            "Name" : fragment,
            "Instance" : core.Instance.Id,
            "Version" : core.Version.Id,
            "DefaultEnvironment" : defaultEnvironment(occurrence, contextLinks),
            "Environment" : {},
            "Links" : contextLinks,
            "DefaultCoreVariables" : true,
            "DefaultEnvironmentVariables" : true,
            "DefaultLinkVariables" : true,
            "Policy" : [],
            "ManagedPolicy" : [],
            "Files" : {},
            "Directories" : {}
        }
    ]

    [#-- Add in fragment specifics including override of defaults --]
    [#assign fragmentListMode = "model"]
    [#local fragmentId = formatFragmentId(_context)]
    [#include fragmentList?ensure_starts_with("/")]

    [#local environmentVariables += getFinalEnvironment(occurrence, _context, operationsBucket, dataBucket ).Environment ]

    [#local configSets +=
        getInitConfigEnvFacts(environmentVariables, false) +
        getInitConfigDirsFiles(_context.Files, _context.Directories) ]

    [#list bootstrapProfile.BootStraps as bootstrapName ]
        [#local bootstrap = bootstraps[bootstrapName]]
        [#local configSets +=
            getInitConfigUserBootstrap(bootstrap, environmentVariables )!{}]
    [/#list]

    [#if deploymentSubsetRequired("iam", true) &&
            isPartOfCurrentDeploymentUnit(ecsRoleId)]
        [#local linkPolicies = getLinkTargetsOutboundRoles(_context.Links) ]

        [@createRole
            mode=listMode
            id=ecsRoleId
            trustedServices=["ec2.amazonaws.com" ]
            managedArns=
                ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"] +
                _context.ManagedPolicy
            policies=
                [
                    getPolicyDocument(
                            s3ListPermission(codeBucket) +
                            s3ReadPermission(credentialsBucket, accountId + "/alm/docker") +
                            fixedIP?then(
                                ec2IPAddressUpdatePermission(),
                                []
                            ) +
                            s3ReadPermission(codeBucket) +
                            s3ListPermission(operationsBucket) +
                            s3WritePermission(operationsBucket, getSegmentBackupsFilePrefix()) +
                            s3WritePermission(operationsBucket, "DOCKERLogs") +
                            cwLogsProducePermission(ecsLogGroupName) +
                            (solution.VolumeDrivers?seq_contains("ebs"))?then(
                                ec2EBSVolumeUpdatePermission(),
                                []
                            ) ,
                        "docker")
                ] +
                arrayIfContent(
                    [getPolicyDocument(_context.Policy, "fragment")],
                    _context.Policy) +
                arrayIfContent(
                    [getPolicyDocument(linkPolicies, "links")],
                    linkPolicies)
        /]

        [@createRole
            mode=listMode
            id=ecsServiceRoleId
            trustedServices=["ecs.amazonaws.com" ]
            managedArns=["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"]
        /]

    [/#if]

    [#if solution.ClusterLogGroup &&
            deploymentSubsetRequired("lg", true) &&
            isPartOfCurrentDeploymentUnit(ecsLogGroupId)]
        [@createLogGroup
            mode=listMode
            id=ecsLogGroupId
            name=ecsLogGroupName /]
    [/#if]

    [#if deploymentSubsetRequired("lg", true) && isPartOfCurrentDeploymentUnit(ecsInstanceLogGroupId) ]
        [@createLogGroup
            mode=listMode
            id=ecsInstanceLogGroupId
            name=ecsInstanceLogGroupName /]
    [/#if]

    [#local configSets +=
        getInitConfigLogAgent(
            logFileProfile,
            ecsInstanceLogGroupName
        )]

    [#if deploymentSubsetRequired("ecs", true)]

        [#list _context.Links as linkId,linkTarget]
            [#local linkTargetCore = linkTarget.Core ]
            [#local linkTargetConfiguration = linkTarget.Configuration ]
            [#local linkTargetResources = linkTarget.State.Resources ]
            [#local linkTargetAttributes = linkTarget.State.Attributes ]

            [#switch linkTargetCore.Type]
                [#case EFS_MOUNT_COMPONENT_TYPE]
                    [#local configSets +=
                        getInitConfigEFSMount(
                            linkTargetCore.Id,
                            linkTargetAttributes.EFS,
                            linkTargetAttributes.DIRECTORY,
                            linkId
                        )]
                    [#break]
            [/#switch]
        [/#list]

        [@createComponentSecurityGroup
            mode=listMode
            occurrence=occurrence
            vpcId=vpcId
        /]

        [#list resources.logMetrics!{} as logMetricName,logMetric ]

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

            [#local monitoredResources = getMonitoredResources(resources, alert.Resource)]
            [#list monitoredResources as name,monitoredResource ]

                [@cfDebug listMode monitoredResource false /]

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
                            dimensions=getResourceMetricDimensions(monitoredResource, resources)
                            dependencies=monitoredResource.Id
                        /]
                    [#break]
                [/#switch]
            [/#list]
        [/#list]

        [#if processorProfile.MaxCount?has_content]
            [#local maxSize = processorProfile.MaxCount ]
        [#else]
            [#local maxSize = processorProfile.MaxPerZone]
            [#if multiAZ]
                [#local maxSize = maxSize * zones?size]
            [/#if]
        [/#if]

        [@createECSCluster
            mode=listMode
            id=ecsId
        /]

        [@cfResource
            mode=listMode
            id=ecsInstanceProfileId
            type="AWS::IAM::InstanceProfile"
            properties=
                {
                    "Path" : "/",
                    "Roles" : [getReference(ecsRoleId)]
                }
            outputs={}
        /]

        [#local allocationIds = [] ]
        [#if fixedIP]
            [#list 1..maxSize as index]
                [@createEIP
                    mode=listMode
                    id=formatComponentEIPId(core.Tier, core.Component, index)
                /]
                [#local allocationIds +=
                    [
                        getReference(formatComponentEIPId(core.Tier, core.Component, index), ALLOCATION_ATTRIBUTE_TYPE)
                    ]
                ]
            [/#list]
        [/#if]

        [#if allocationIds?has_content ]
            [#local configSets +=
                getInitConfigEIPAllocation(allocationIds)]
        [/#if]

        [@createEc2AutoScaleGroup
            mode=listMode
            id=ecsAutoScaleGroupId
            tier=core.Tier
            configSetName=configSetName
            configSets=configSets
            launchConfigId=ecsLaunchConfigId
            processorProfile=processorProfile
            autoScalingConfig=solution.AutoScaling
            multiAZ=multiAZ
            tags=ecsTags
            networkResources=networkResources
            hibernate=hibernate
        /]

        [@createEC2LaunchConfig
            mode=listMode
            id=ecsLaunchConfigId
            processorProfile=processorProfile
            storageProfile=storageProfile
            instanceProfileId=ecsInstanceProfileId
            securityGroupId=ecsSecurityGroupId
            resourceId=ecsAutoScaleGroupId
            imageId=regionObject.AMIs.Centos.ECS
            publicIP=publicRouteTable
            configSet=configSetName
            environmentId=environmentId
            enableCfnSignal=solution.AutoScaling.WaitForSignal
            keyPairId=sshKeyPairId
        /]
    [/#if]
[/#macro]

[#macro aws_ecs_cf_application occurrence ]
    [@cfDebug listMode occurrence false /]

    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["prologue", "template", "epilogue", "cli"])
        /]
        [#return]
    [/#if]

    [#local parentResources = occurrence.State.Resources]
    [#local parentSolution = occurrence.Configuration.Solution ]

    [#local ecsId = parentResources["cluster"].Id ]
    [#local ecsSecurityGroupId = parentResources["securityGroup"].Id ]
    [#local ecsServiceRoleId = parentResources["serviceRole"].Id ]

    [#-- Baseline component lookup --]
    [#local baselineComponentIds = getBaselineLinks(parentSolution.Profiles.Baseline, [ "OpsData", "AppData", "Encryption" ] )]
    [#local operationsBucket = getExistingReference(baselineComponentIds["OpsData"]) ]

    [#local occurrenceNetwork = getOccurrenceNetwork(occurrence) ]
    [#local networkLink = occurrenceNetwork.Link!{} ]

    [#local networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]
    [#if ! networkLinkTarget?has_content ]
        [@cfException listMode "Network could not be found" networkLink /]
        [#return]
    [/#if]

    [#local networkConfiguration = networkLinkTarget.Configuration.Solution]
    [#local networkResources = networkLinkTarget.State.Resources ]

    [#local routeTableLinkTarget = getLinkTarget(occurrence, networkLink + { "RouteTable" : occurrenceNetwork.RouteTable })]
    [#local routeTableConfiguration = routeTableLinkTarget.Configuration.Solution ]
    [#local publicRouteTable = routeTableConfiguration.Public ]

    [#local vpcId = networkResources["vpc"].Id ]

    [#local hibernate = parentSolution.Hibernate.Enabled &&
                            getExistingReference(ecsId)?has_content ]

    [#list requiredOccurrences(
            occurrence.Occurrences![],
            deploymentUnit) as subOccurrence]

        [@cfDebug listMode subOccurrence false /]

        [#local core = subOccurrence.Core ]
        [#local solution = subOccurrence.Configuration.Solution ]
        [#local resources = subOccurrence.State.Resources]

        [#local taskId = resources["task"].Id ]
        [#local taskName = resources["task"].Name ]
        [#local containers = getTaskContainers(occurrence, subOccurrence) ]

        [#local networkMode = solution.NetworkMode ]
        [#local lbTargetType = "instance"]
        [#local networkLinks = [] ]
        [#local engine = solution.Engine?lower_case ]
        [#local executionRoleId = ""]

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

            [#local lbTargetType = "ip" ]

            [#local ecsSecurityGroupId = resources["securityGroup"].Id ]
            [#local ecsSecurityGroupName = resources["securityGroup"].Name ]

            [#local subnets = multiAZ?then(
                getSubnets(core.Tier, networkResources),
                getSubnets(core.Tier, networkResources)[0..0]
            )]

            [#local aswVpcNetworkConfiguration =
                {
                    "AwsvpcConfiguration" : {
                        "SecurityGroups" : getReferences(ecsSecurityGroupId),
                        "Subnets" : subnets,
                        "AssignPublicIp" : publicRouteTable?then("ENABLED", "DISABLED" )
                    }
                }
            ]

            [#if deploymentSubsetRequired("ecs", true)]
                [@createSecurityGroup
                    mode=listMode
                    id=ecsSecurityGroupId
                    name=ecsSecurityGroupName
                    occurrence=occurrence
                    vpcId=vpcId /]
            [/#if]
        [/#if]

        [#if core.Type == ECS_SERVICE_COMPONENT_TYPE]

            [#local serviceId = resources["service"].Id  ]
            [#local serviceDependencies = []]

            [#if deploymentSubsetRequired("ecs", true)]

                [#local loadBalancers = [] ]
                [#local serviceRegistries = []]
                [#local dependencies = [] ]
                [#list containers as container]

                    [#-- allow local network comms between containers in the same service --]
                    [#if solution.ContainerNetworkLinks ]
                        [#if networkMode == "bridge" || engine != "fargate" ]
                            [#local networkLinks += [ container.Name ] ]
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
                            [#local loadBalancer = portMapping.LoadBalancer]
                            [#local link = container.Links[loadBalancer.Link] ]
                            [@cfDebug listMode link false /]
                            [#local linkCore = link.Core ]
                            [#local linkResources = link.State.Resources ]
                            [#local linkConfiguration = link.Configuration.Solution ]
                            [#local linkAttributes = link.State.Attributes ]
                            [#local targetId = "" ]

                            [#local sourceSecurityGroupIds = []]
                            [#local sourceIPAddressGroups = [] ]

                            [#switch linkCore.Type]

                                [#case LB_PORT_COMPONENT_TYPE]

                                    [#switch linkAttributes["ENGINE"] ]
                                        [#case "application" ]
                                        [#case "classic"]
                                            [#local sourceSecurityGroupIds += [ linkResources["sg"].Id ] ]
                                            [#break]
                                        [#case "network" ]
                                            [#local sourceIPAddressGroups = linkConfiguration.IPAddressGroups + [ "_localnet" ] ]
                                            [#break]
                                    [/#switch]

                                    [#switch linkAttributes["ENGINE"] ]
                                        [#case "network" ]
                                        [#case "application" ]
                                            [#local loadBalancers +=
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

                                            [#local lbId =  linkAttributes["LB"] ]
                                            [#-- Classic ELB's register the instance so we only need 1 registration --]
                                            [#-- TODO: Change back to += when AWS allows multiple load balancer registrations per container --]
                                            [#local loadBalancers =
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

                            [#local dependencies += [targetId] ]

                            [#local securityGroupCIDRs = getGroupCIDRs(sourceIPAddressGroups, true, subOccurrence)]
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

                        [#if portMapping.ServiceRegistry?has_content]
                            [#local serviceRegistry = portMapping.ServiceRegistry]
                            [#local link = container.Links[serviceRegistry.Link] ]
                            [@cfDebug listMode link false /]
                            [#local linkCore = link.Core ]
                            [#local linkResources = link.State.Resources ]
                            [#local linkConfiguration = link.Configuration.Solution ]
                            [#local linkAttributes = link.State.Attributes ]

                            [#switch linkCore.Type]

                                [#case SERVICE_REGISTRY_SERVICE_COMPONENT_TYPE]

                                    [#local serviceRecordTypes = linkAttributes["RECORD_TYPES"]?split(",") ]

                                    [#local portAttributes = {}]
                                    [#if serviceRecordTypes?seq_contains("SRV") ]
                                        [#local portAttributes = {
                                            "ContainerPort" : ports[portMapping.ContainerPort].Port
                                        }]
                                    [/#if]

                                    [#if serviceRecordTypes?seq_contains("A") && networkMode != "awsvpc" ]
                                        [@cfException listMode "A record registration only availalbe on awsvpc network Type" link /]
                                    [/#if]

                                    [#if serviceRecordTypes?seq_contains("AAAA") ]
                                        [@cfException listMode "AAAA Service record are not supported" link /]
                                    [/#if]

                                    [#local serviceRegistries +=
                                        [
                                            {
                                                "ContainerName" : container.Name,
                                                "RegistryArn" : linkAttributes["SERVICE_ARN"]
                                            } +
                                            portAttributes
                                        ]
                                    ]
                                    [#break]
                            [/#switch]
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

                [#local desiredCount = (solution.DesiredCount >= 0)?then(
                            solution.DesiredCount,
                            multiAZ?then(zones?size,1)
                        ) ]

                [#if hibernate ]
                    [#local desiredCount = 0 ]
                [/#if]

                [@createECSService
                    mode=listMode
                    id=serviceId
                    ecsId=ecsId
                    engine=engine
                    desiredCount=desiredCount
                    taskId=taskId
                    loadBalancers=loadBalancers
                    serviceRegistries=serviceRegistries
                    roleId=ecsServiceRoleId
                    networkMode=networkMode
                    networkConfiguration=aswVpcNetworkConfiguration!{}
                    placement=solution.Placement
                    dependencies=dependencies
                /]
            [/#if]
        [/#if]

        [#local dependencies = [] ]
        [#local roleId = "" ]
        [#if solution.UseTaskRole]
            [#local roleId = resources["taskrole"].Id ]
            [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(roleId)]
                [#local managedPolicy = []]

                [#list containers as container]
                    [#if container.ManagedPolicy?has_content ]
                        [#local managedPolicy += container.ManagedPolicy ]
                    [/#if]

                    [#if container.Policy?has_content]
                        [#local policyId = formatDependentPolicyId(taskId, container.Id) ]
                        [@createPolicy
                            mode=listMode
                            id=policyId
                            name=container.Name
                            statements=container.Policy
                            roles=roleId
                        /]
                        [#local dependencies += [policyId] ]
                    [/#if]

                    [#local linkPolicies = getLinkTargetsOutboundRoles(container.Links) ]

                    [#if linkPolicies?has_content]
                        [#local policyId = formatDependentPolicyId(taskId, container.Id, "links")]
                        [@createPolicy
                            mode=listMode
                            id=policyId
                            name="links"
                            statements=linkPolicies
                            roles=roleId
                        /]
                        [#local dependencies += [policyId] ]
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

        [#local executionRoleId = ""]
        [#if resources["executionRole"]?has_content ]
            [#local executionRoleId = resources["executionRole"].Id]
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

                [#local scheduleTaskRoleId = resources["scheduleRole"].Id ]

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

                    [#local scheduleRuleId = formatEventRuleId(subOccurrence, "schedule", schedule.Id) ]
                    [#local scheduleEnabled = hibernate?then(
                                false,
                                schedule.Enabled
                    )]

                    [#if networkMode == "awsvpc" ]

                        [#-- Cloudfomation support not available for awsvpc network config which means that fargate isn't supported --]
                        [#local eventRuleCliConfig =
                            {
                                "ScheduleExpression" : schedule.Expression,
                                "State" : scheduleEnabled?then("ENABLED", "DISABLED")
                            }]

                        [#local eventTargetCliConfig =
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

                        [#local ruleCliId = formatId(taskId, "rule")]
                        [#local ruleCommand = "updateEventRule" ]
                        [#local targetCliId = formatId(taskId, "target")]
                        [#local targetCommand = "updateTargetRule" ]

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

                            [#local targetParameters = {
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
                [#local lgId = resources["lg"].Id ]
                [#local lgName = resources["lg"].Name]
                [#if isPartOfCurrentDeploymentUnit(lgId) ]
                    [@createLogGroup
                        mode=listMode
                        id=lgId
                        name=lgName /]
                [/#if]
            [/#if]
            [#list containers as container]
                [#if container.LogGroup?has_content]
                    [#local lgId = container.LogGroup.Id ]
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

                        [#local lgId = container.LogGroup.Id ]
                        [#local lgName = container.LogGroup.Name ]

                        [#local logMetricId = formatDependentLogMetricId(lgId, logMetric.Id)]

                        [#local containerLogMetricName = getMetricName(
                                logMetric.Name,
                                AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE,
                                formatName(core.ShortFullName, container.Name) )]

                        [#local logFilter = logFilters[logMetric.LogFilter].Pattern ]

                        [#local resources += {
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

            [#list resources.logMetrics!{} as logMetricName,logMetric ]

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

                [#local monitoredResources = getMonitoredResources(resources, alert.Resource)]
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
                [#local fragmentId = formatFragmentId(container, occurrence)]
                [#include fragmentList?ensure_starts_with("/")]
            [/#list]

        [/#if]

        [#if deploymentSubsetRequired("prologue", false)]
            [#-- Copy any asFiles needed by the task --]
            [#local asFiles = getAsFileSettings(subOccurrence.Configuration.Settings.Product) ]
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
[/#macro]

