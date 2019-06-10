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
            getInitConfigBootstrap(occurrence) +
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
    [#local fragmentListMode = "model"]
    [#local fragmentId = formatFragmentId(_context)]
    [#include fragmentList?ensure_starts_with("/")]

    [#local environmentVariables += getFinalEnvironment(occurrence, _context).Environment ]

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
        /]
    [/#if]
[/#macro]
