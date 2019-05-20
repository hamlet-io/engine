[#-- ECS --]

[#if componentType == ECS_COMPONENT_TYPE]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]

        [#assign ecsId = resources["cluster"].Id ]
        [#assign ecsName = resources["cluster"].Name ]
        [#assign ecsRoleId = resources["role"].Id ]
        [#assign ecsServiceRoleId = resources["serviceRole"].Id ]
        [#assign ecsInstanceProfileId = resources["instanceProfile"].Id ]
        [#assign ecsAutoScaleGroupId = resources["autoScaleGroup"].Id ]
        [#assign ecsLaunchConfigId = resources["launchConfig"].Id ]
        [#assign ecsSecurityGroupId = resources["securityGroup"].Id ]
        [#assign ecsLogGroupId = resources["lg"].Id ]
        [#assign ecsLogGroupName = resources["lg"].Name ]
        [#assign ecsInstanceLogGroupId = resources["lgInstanceLog"].Id]
        [#assign ecsInstanceLogGroupName = resources["lgInstanceLog"].Name]
        [#assign defaultLogDriver = solution.LogDriver ]
        [#assign fixedIP = solution.FixedIP ]

        [#assign hibernate = solution.Hibernate.Enabled &&
                                getExistingReference(ecsId)?has_content ]

        [#assign logFileProfile = getLogFileProfile(tier, component, "ECS")]
        [#assign bootstrapProfile = getBootstrapProfile(tier, component, "ECS")]
        [#assign processorProfile = getProcessor(occurrence, "ECS")]
        [#assign storageProfile = getStorage(tier, component, "ECS")]

        [#assign networkLink = tier.Network.Link!{} ]

        [#assign networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]

        [#if ! networkLinkTarget?has_content ]
            [@cfException listMode "Network could not be found" networkLink /]
            [#break]
        [/#if]

        [#assign networkConfiguration = networkLinkTarget.Configuration.Solution]
        [#assign networkResources = networkLinkTarget.State.Resources ]

        [#assign vpcId = networkResources["vpc"].Id ]

        [#assign routeTableLinkTarget = getLinkTarget(occurrence, networkLink + { "RouteTable" : tier.Network.RouteTable })]
        [#assign routeTableConfiguration = routeTableLinkTarget.Configuration.Solution ]
        [#assign publicRouteTable = routeTableConfiguration.Public ]

        [#assign ecsTags = getCfTemplateCoreTags(
                        ecsName,
                        tier,
                        component,
                        "",
                        true)]

        [#assign environmentVariables = {}]

        [#assign configSetName = componentType ]
        [#assign configSets =
                getInitConfigDirectories() +
                getInitConfigBootstrap(component.Role!"") +
                getInitConfigECSAgent(ecsId, defaultLogDriver, solution.DockerUsers, solution.VolumeDrivers ) ]

        [#assign efsMountPoints = {}]

        [#assign fragment =
            contentIfContent(solution.Fragment, getComponentId(component)) ]

        [#assign contextLinks = getLinkTargets(occurrence) ]
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
        [#assign fragmentId = formatFragmentId(_context)]
        [#include fragmentList?ensure_starts_with("/")]

        [#assign environmentVariables += getFinalEnvironment(occurrence, _context).Environment ]

        [#assign configSets +=
            getInitConfigEnvFacts(environmentVariables, false) +
            getInitConfigDirsFiles(_context.Files, _context.Directories) ]

        [#list bootstrapProfile.BootStraps as bootstrapName ]
            [#assign bootstrap = bootstraps[bootstrapName]]
            [#assign configSets +=
                getInitConfigUserBootstrap(bootstrap, environmentVariables )!{}]
        [/#list]

        [#if deploymentSubsetRequired("iam", true) &&
                isPartOfCurrentDeploymentUnit(ecsRoleId)]
            [#assign linkPolicies = getLinkTargetsOutboundRoles(_context.Links) ]

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

        [#assign configSets +=
            getInitConfigLogAgent(
                logFileProfile,
                ecsInstanceLogGroupName
            )]

        [#if deploymentSubsetRequired("ecs", true)]

            [#list _context.Links as linkId,linkTarget]
                [#assign linkTargetCore = linkTarget.Core ]
                [#assign linkTargetConfiguration = linkTarget.Configuration ]
                [#assign linkTargetResources = linkTarget.State.Resources ]
                [#assign linkTargetAttributes = linkTarget.State.Attributes ]

                [#switch linkTargetCore.Type]
                    [#case EFS_MOUNT_COMPONENT_TYPE]
                        [#assign configSets +=
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
                tier=tier
                component=component
                vpcId=vpcId /]

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

                [#assign monitoredResources = getMonitoredResources(resources, alert.Resource)]
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
                [#assign maxSize = processorProfile.MaxCount ]
            [#else]
                [#assign maxSize = processorProfile.MaxPerZone]
                [#if multiAZ]
                    [#assign maxSize = maxSize * zones?size]
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

            [#assign allocationIds = [] ]
            [#if fixedIP]
                [#list 1..maxSize as index]
                    [@createEIP
                        mode=listMode
                        id=formatComponentEIPId(tier, component, index)
                    /]
                    [#assign allocationIds +=
                        [
                            getReference(formatComponentEIPId(tier, component, index), ALLOCATION_ATTRIBUTE_TYPE)
                        ]
                    ]
                [/#list]
            [/#if]

            [#if allocationIds?has_content ]
                [#assign configSets +=
                    getInitConfigEIPAllocation(allocationIds)]
            [/#if]

            [@createEc2AutoScaleGroup
                mode=listMode
                id=ecsAutoScaleGroupId
                tier=tier
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
    [/#list]
[/#if]
