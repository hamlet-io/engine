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

        [#assign logFileProfile = getLogFileProfile(tier, component, "ECS")]
        [#assign bootstrapProfile = getBootstrapProfile(tier, component, "ECS")]
        [#assign processorProfile = getProcessor(tier, component, "ECS")]
        [#assign storageProfile = getStorage(tier, component, "ECS")]

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
                getInitConfigECSAgent(ecsId, defaultLogDriver, solution.DockerUsers) ]

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
                                cwLogsProducePermission(ecsLogGroupName),
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
                component=component /]


            [#assign maxSize = processorProfile.MaxPerZone]
            [#if multiAZ]
                [#assign maxSize = maxSize * zones?size]
            [/#if]


            [@cfResource
                mode=listMode
                id=ecsId
                type="AWS::ECS::Cluster"
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
                minUpdateInstances=solution.AutoScaling.MinUpdateInstances
                replaceOnUpdate=solution.AutoScaling.ReplaceCluster
                waitOnSignal=solution.AutoScaling.WaitForSignal
                startupTimeout=solution.AutoScaling.StartupTimeout
                updatePauseTime=solution.AutoScaling.UpdatePauseTime
                activityCooldown=solution.AutoScaling.ActivityCooldown  
                multiAZ=multiAZ
                tags=ecsTags
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
                routeTable=tier.Network.RouteTable
                configSet=configSetName
                environmentId=environmentId
                enableCfnSignal=solution.AutoScaling.WaitForSignal
            /]
        [/#if]
    [/#list]
[/#if]
