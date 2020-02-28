[#ftl]
[#macro aws_computecluster_cf_generationcontract_application occurrence ]
    [@addDefaultGenerationContract subsets="template" /]
[/#macro]

[#macro aws_computecluster_cf_setup_application occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]
    [#local links = solution.Links ]

    [#local dockerHost = solution.DockerHost]

    [#local computeClusterRoleId               = resources["role"].Id ]
    [#local computeClusterInstanceProfileId    = resources["instanceProfile"].Id ]
    [#local computeClusterAutoScaleGroupId     = resources["autoScaleGroup"].Id ]
    [#local computeClusterAutoScaleGroupName   = resources["autoScaleGroup"].Name ]
    [#local computeClusterLaunchConfigId       = resources["launchConfig"].Id ]
    [#local computeClusterSecurityGroupId      = resources["securityGroup"].Id ]
    [#local computeClusterSecurityGroupName    = resources["securityGroup"].Name ]
    [#local computeClusterLogGroupId           = resources["lg"].Id]
    [#local computeClusterLogGroupName         = resources["lg"].Name]

    [#local processorProfile = getProcessor(occurrence, "ComputeCluster")]
    [#local storageProfile   = getStorage(occurrence, "ComputeCluster")]
    [#local logFileProfile   = getLogFileProfile(occurrence, "ComputeCluster")]
    [#local bootstrapProfile = getBootstrapProfile(occurrence, "ComputeCluster")]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "OpsData", "AppData", "Encryption", "SSHKey" ] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]
    [#local operationsBucket = getExistingReference(baselineComponentIds["OpsData"]) ]
    [#local dataBucket = getExistingReference(baselineComponentIds["AppData"])]

    [#local occurrenceNetwork = getOccurrenceNetwork(occurrence) ]
    [#local networkLink = occurrenceNetwork.Link!{} ]

    [#local networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]

    [#if ! networkLinkTarget?has_content ]
        [@fatal message="Network could not be found" context=networkLink /]
        [#return]
    [/#if]

    [#local networkConfiguration = networkLinkTarget.Configuration.Solution]
    [#local networkResources = networkLinkTarget.State.Resources ]

    [#local vpcId = networkResources["vpc"].Id ]

    [#local routeTableLinkTarget = getLinkTarget(occurrence, networkLink + { "RouteTable" : occurrenceNetwork.RouteTable })]
    [#local routeTableConfiguration = routeTableLinkTarget.Configuration.Solution ]
    [#local publicRouteTable = routeTableConfiguration.Public ]

    [#local computeAutoScaleGroupTags =
            getOccurrenceCoreTags(
                    occurrence,
                    computeClusterAutoScaleGroupName,
                    "",
                    true)]

    [#local targetGroupPermission = false ]
    [#local targetGroups = [] ]
    [#local loadBalancers = [] ]
    [#local environmentVariables = {}]

    [#local configSetName = occurrence.Core.Type]

    [#local ingressRules = []]

    [#list solution.Ports?values as port ]
        [#if port.LB.Configured]
            [#local lbLink = getLBLink(occurrence, port)]
            [#if isDuplicateLink(links, lbLink) ]
                [@fatal
                    message="Duplicate Link Name"
                    context=links
                    detail=lbLink /]
                [#continue]
            [/#if]
            [#local links += lbLink]
        [#else]
            [#local portCIDRs = getGroupCIDRs(port.IPAddressGroups, true, occurrence) ]
            [#if portCIDRs?has_content]
                [#local ingressRules +=
                    [{
                        "Port" : port.Name,
                        "CIDR" : portCIDRs
                    }]]
            [/#if]
        [/#if]
    [/#list]

    [#local configSets =
            getInitConfigDirectories() +
            getInitConfigBootstrap(occurrence, operationsBucket, dataBucket) ]

    [#local scriptsPath =
            formatRelativePath(
            getRegistryEndPoint("scripts", occurrence),
            getRegistryPrefix("scripts", occurrence),
            productName,
            getOccurrenceBuildScopeExtension(occurrence),
            getOccurrenceBuildUnit(occurrence),
            getOccurrenceBuildReference(occurrence)
            ) ]

    [#local scriptsFile =
        formatRelativePath(
            scriptsPath,
            "scripts.zip"
        )
    ]

    [#local fragment = getOccurrenceFragmentBase(occurrence) ]

    [#local contextLinks = getLinkTargets(occurrence, links) ]
    [#assign _context =
        {
            "Id" : fragment,
            "Name" : fragment,
            "Instance" : core.Instance.Id,
            "Version" : core.Version.Id,
            "DefaultEnvironment" : defaultEnvironment(occurrence, contextLinks, baselineLinks),
            "Environment" : {},
            "Links" : contextLinks,
            "BaselineLinks" : baselineLinks,
            "DefaultCoreVariables" : true,
            "DefaultEnvironmentVariables" : true,
            "DefaultLinkVariables" : true,
            "DefaultBaselineVariables" : true,
            "Policy" : [],
            "ManagedPolicy" : [],
            "Files" : {},
            "Directories" : {}
        }
    ]

    [#-- Add in fragment specifics including override of defaults --]
    [#local fragmentId = formatFragmentId(_context)]
    [#include fragmentList?ensure_starts_with("/")]

    [#local environmentVariables += getFinalEnvironment(occurrence, _context ).Environment ]

    [#local configSets +=
        getInitConfigEnvFacts(environmentVariables, false) +
        getInitConfigDirsFiles(_context.Files, _context.Directories) ]

    [#list bootstrapProfile.BootStraps as bootstrapName ]
        [#local bootstrap = bootstraps[bootstrapName]]
        [#local configSets +=
            getInitConfigUserBootstrap(bootstrapName, bootstrap, environmentVariables )!{}]
    [/#list]

    [#if deploymentSubsetRequired("iam", true) &&
            isPartOfCurrentDeploymentUnit(computeClusterRoleId)]
        [@createRole
            id=computeClusterRoleId
            trustedServices=["ec2.amazonaws.com" ]
            policies=
                [
                    getPolicyDocument(
                        s3ReadPermission(
                            formatRelativePath(
                                getRegistryEndPoint("scripts", occurrence),
                                getRegistryPrefix("scripts", occurrence)
                            )
                        ) +
                        s3ListPermission(codeBucket) +
                        s3ReadPermission(codeBucket) +
                        s3ListPermission(operationsBucket) +
                        s3WritePermission(operationsBucket, "DOCKERLogs") +
                        s3WritePermission(operationsBucket, "Backups") +
                        cwLogsProducePermission(computeClusterLogGroupName),
                        "basic")
                ] +
                targetGroupPermission?then(
                    [
                        getPolicyDocument(
                            lbRegisterTargetPermission(),
                            "loadbalancing")
                    ],
                    []
                ) +
                arrayIfContent(
                    [getPolicyDocument(_context.Policy, "fragment")],
                    _context.Policy)
            managedArns=
                _context.ManagedPolicy
        /]

    [/#if]

    [#list links?values as link]
        [#local linkTarget = getLinkTarget(occurrence, link) ]

        [@debug message="Link Target" context=linkTarget enabled=false /]

        [#if !linkTarget?has_content]
            [#continue]
        [/#if]

        [#local linkTargetCore = linkTarget.Core ]
        [#local linkTargetConfiguration = linkTarget.Configuration ]
        [#local linkTargetResources = linkTarget.State.Resources ]
        [#local linkTargetAttributes = linkTarget.State.Attributes ]

        [#local sourceSecurityGroupIds = []]
        [#local sourceIPAddressGroups = [] ]

        [#switch linkTargetCore.Type]
            [#case LB_PORT_COMPONENT_TYPE]
                [#local targetGroupPermission = true]
                [#local destinationPort = linkTargetAttributes["DESTINATION_PORT"]]

                [#switch linkTargetAttributes["ENGINE"] ]
                    [#case "application" ]
                    [#case "classic"]
                        [#local sourceSecurityGroupIds += [ linkTargetResources["sg"].Id ] ]
                        [#break]
                    [#case "network" ]
                        [#local sourceIPAddressGroups = linkTargetConfiguration.IPAddressGroups + [ "_localnet" ] ]
                        [#break]
                [/#switch]

                [#switch linkTargetAttributes["ENGINE"]]

                    [#case "application"]
                    [#case "network"]
                        [#local targetGroups += [ linkTargetAttributes["TARGET_GROUP_ARN"] ] ]
                        [#break]

                    [#case "classic" ]
                        [#local lbId = linkTargetAttributes["LB"] ]
                        [#-- Classic ELB's register the instance so we only need 1 registration --]
                        [#local loadBalancers += [ getExistingReference(lbId) ]]
                        [#break]
                    [/#switch]
                [#break]
            [#case EFS_MOUNT_COMPONENT_TYPE]
                [#local configSets +=
                    getInitConfigEFSMount(
                        linkTargetCore.Id,
                        linkTargetAttributes.EFS,
                        linkTargetAttributes.DIRECTORY,
                        link.Id
                    )]
                [#break]
        [/#switch]

        [#if deploymentSubsetRequired(COMPUTECLUSTER_COMPONENT_TYPE, true)]

            [#local securityGroupCIDRs = getGroupCIDRs(sourceIPAddressGroups, true, occurrence)]
            [#list securityGroupCIDRs as cidr ]

                [@createSecurityGroupIngress
                    id=
                        formatDependentSecurityGroupIngressId(
                            computeClusterSecurityGroupId,
                            link.Id,
                            destinationPort,
                            replaceAlphaNumericOnly(cidr)
                        )
                    port=destinationPort
                    cidr=cidr
                    groupId=computeClusterSecurityGroupId
            /]
            [/#list]

            [#list sourceSecurityGroupIds as group ]
                [@createSecurityGroupIngress
                    id=
                        formatDependentSecurityGroupIngressId(
                            computeClusterSecurityGroupId,
                            link.Id,
                            destinationPort
                        )
                    port=destinationPort
                    cidr=group
                    groupId=computeClusterSecurityGroupId
                /]
            [/#list]
        [/#if]
    [/#list]

    [#local configSets += getInitConfigScriptsDeployment(scriptsFile, environmentVariables, solution.UseInitAsService, false)]

    [#if deploymentSubsetRequired("lg", true) && isPartOfCurrentDeploymentUnit(computeClusterLogGroupId) ]
        [@createLogGroup
            id=computeClusterLogGroupId
            name=computeClusterLogGroupName /]
    [/#if]

    [#local configSets +=
        getInitConfigLogAgent(
            logFileProfile,
            computeClusterLogGroupName
        )]

    [#if deploymentSubsetRequired(COMPUTECLUSTER_COMPONENT_TYPE, true)]

        [#if solution.ScalingPolicies?has_content ]
            [#list solution.ScalingPolicies as name, scalingPolicy ]
                [#local scalingPolicyId = resources["scalingPolicy" + name].Id ]

                [#local scalingMetricTrigger = scalingPolicy.TrackingResource.MetricTrigger ]

                [#switch scalingPolicy.Type?lower_case ]
                    [#case "stepped"]
                    [#case "tracked"]

                        [#if isPresent(scalingPolicy.TrackingResource.Link) ]

                            [#local scalingPolicyLink = scalingPolicy.TrackingResource.Link ]
                            [#local scalingPolicyLinkTarget = getLinkTarget(subOccurrence, scalingPolicyLink, false) ]

                            [@debug message="Scaling Link Target" context=scalingPolicyLinkTarget enabled=false /]

                            [#if !scalingPolicyLinkTarget?has_content]
                                [#continue]
                            [/#if]

                            [#local scalingTargetCore = scalingPolicyLinkTarget.Core ]
                            [#local scalingTargetResources = scalingPolicyLinkTarget.State.Resources ]
                        [#else]
                            [#local scalingTargetCore = core]
                            [#local scalingTargetResources = resources ]
                        [/#if]

                        [#local monitoredResources = getMonitoredResources(core.Id, scalingTargetResources, scalingMetricTrigger.Resource)]

                        [#if monitoredResources?keys?size > 1 ]
                            [@fatal
                                message="A scaling policy can only track one metric"
                                context={ "trackingPolicy" : name, "monitoredResources" : monitoredResources }
                                detail="Please add an extra resource filter to the metric policy"
                            /]
                            [#continue]
                        [/#if]

                        [#if ! monitoredResources?has_content ]
                            [@fatal
                                message="Could not find monitoring resources"
                                context={ "scalingPolicy" : scalingPolicy }
                                detail="Please make sure you have a resource which can be monitored with CloudWatch"
                            /]
                            [#continue]
                        [/#if]

                        [#local monitoredResource = monitoredResources[ (monitoredResources?keys)[0]] ]

                        [#local metricDimensions = getResourceMetricDimensions(monitoredResource, scalingTargetResources )]
                        [#local metricName = getMetricName(scalingMetricTrigger.Metric, monitoredResource.Type, scalingTargetCore.ShortFullName)]
                        [#local metricNamespace = getResourceMetricNamespace(monitoredResource.Type)]

                        [#if scalingPolicy.Type?lower_case == "stepped" ]
                            [#if ! isPresent( scalingPolicy.Stepped )]
                                [@fatal
                                    message="Stepped Scaling policy not found"
                                    context=scalingPolicy
                                    enabled=true
                                /]
                                [#continue]
                            [/#if]

                            [@createAlarm
                                id=formatDependentAlarmId(scalingPolicyId, monitoredResource.Id )
                                severity="Scaling"
                                resourceName=scalingTargetCore.FullName
                                alertName=scalingMetricTrigger.Name
                                actions=getReference( scalingPolicyId )
                                reportOK=false
                                metric=metricName
                                namespace=metricNamespace
                                description=scalingMetricTrigger.Name
                                threshold=scalingMetricTrigger.Threshold
                                statistic=scalingMetricTrigger.Statistic
                                evaluationPeriods=scalingMetricTrigger.Periods
                                period=scalingMetricTrigger.Time
                                operator=scalingMetricTrigger.Operator
                                missingData=scalingMetricTrigger.MissingData
                                unit=scalingMetricTrigger.Unit
                                dimensions=metricDimensions
                            /]

                            [#local scalingAction = []]
                            [#list scalingPolicy.Stepped.Adjustments?values as adjustment ]
                                    [#local scalingAction +=
                                                    getAutoScalingStepAdjustment(
                                                            adjustment.AdjustmentValue,
                                                            adjustment.LowerBound,
                                                            adjustment.UpperBound
                                                )]
                            [/#list]

                        [/#if]

                        [#if scalingPolicy.Type?lower_case == "tracked" ]

                            [#if ! isPresent( scalingPolicy.Tracked )]
                                [@fatal
                                    message="Tracked Scaling policy not found"
                                    context=scalingPolicy
                                    enabled=true
                                /]
                                [#continue]
                            [/#if]

                            [#local metricSpecification = getAutoScalingCustomTrackMetric(
                                                            getResourceMetricDimensions(monitoredResource, scalingTargetResources ),
                                                            getMetricName(scalingMetricTrigger.Metric, monitoredResource.Type, scalingTargetCore.ShortFullName),
                                                            getResourceMetricNamespace(monitoredResource.Type),
                                                            scalingMetricTrigger.Statistic
                                                        )]

                            [#local scalingAction = getEc2AutoScalingTrackPolicy(
                                                        scalingPolicy.Tracked.ScaleInEnabled,
                                                        scalingPolicy.Tracked.TargetValue,
                                                        metricSpecification
                                                    )]
                        [/#if]

                        [@createEc2AutoScalingPolicy
                                id=scalingPolicyId
                                autoScaleGroupId=computeClusterAutoScaleGroupId
                                scalingAction=scalingAction
                                policyType=scalingPolicy.Type
                                metricAggregationType=scalingPolicy.Stepped.MetricAggregation
                                adjustmentType=scalingPolicy.Stepped.CapacityAdjustment
                                minAdjustment=scalingPolicy.Stepped.MinAdjustment
                        /]
                        [#break]

                    [#case "scheduled"]
                        [#if ! isPresent( scalingPolicy.Scheduled )]
                            [@fatal
                                message="Scheduled Scaling policy not found"
                                context=scalingPolicy
                                enabled=true
                            /]
                            [#continue]
                        [/#if]

                        [#local scheduleProcessor = getProcessor(
                                                        occurrence,
                                                        "ComputeCluster",
                                                        scalingPolicy.Scheduled.ProcessorProfile)]
                        [#local scheduleProcessorCounts = getProcessorCounts(scheduleProcessor, multiAZ ) ]
                        [@createEc2AutoScalingSchedule
                            id=scalingPolicyId
                            autoScaleGroupId=computeClusterAutoScaleGroupId
                            schedule=scalingPolicy.Scheduled.Schedule
                            processorCount=scheduleProcessorCounts
                        /]
                        [#break]
                [/#switch]
            [/#list]
        [/#if]


        [@createSecurityGroup
            occurrence=occurrence
            id=computeClusterSecurityGroupId
            name=computeClusterSecurityGroupName
            vpcId=vpcId /]

        [#list ingressRules as rule ]
            [@createSecurityGroupIngress
                    id=formatDependentSecurityGroupIngressId(
                        computeClusterSecurityGroupId,
                        rule.Port)
                    port=rule.Port
                    cidr=rule.CIDR
                    groupId=computeClusterSecurityGroupId /]
        [/#list]

        [@cfResource
            id=computeClusterInstanceProfileId
            type="AWS::IAM::InstanceProfile"
            properties=
                {
                    "Path" : "/",
                    "Roles" : [getReference(computeClusterRoleId)]
                }
            outputs={}
        /]


        [#local autoScalingConfig = solution.AutoScaling + {
                                            "WaitForSignal" : (solution.UseInitAsService != true)
                                    }]

        [@createEc2AutoScaleGroup
            id=computeClusterAutoScaleGroupId
            tier=core.Tier
            configSetName=configSetName
            configSets=configSets
            launchConfigId=computeClusterLaunchConfigId
            processorProfile=processorProfile
            autoScalingConfig=autoScalingConfig
            multiAZ=multiAZ
            targetGroups=targetGroups
            loadBalancers=loadBalancers
            tags=computeAutoScaleGroupTags
            networkResources=networkResources
        /]

        [#local imageId = dockerHost?then(
            regionObject.AMIs.Centos.ECS,
            regionObject.AMIs.Centos.EC2
        )]

        [@createEC2LaunchConfig
            id=computeClusterLaunchConfigId
            processorProfile=processorProfile
            storageProfile=storageProfile
            securityGroupId=computeClusterSecurityGroupId
            instanceProfileId=computeClusterInstanceProfileId
            resourceId=computeClusterAutoScaleGroupId
            imageId=imageId
            publicIP=publicRouteTable
            configSet=configSetName
            enableCfnSignal=(solution.UseInitAsService != true)
            environmentId=environmentId
            keyPairId=baselineComponentIds["SSHKey"]
        /]
    [/#if]
[/#macro]
