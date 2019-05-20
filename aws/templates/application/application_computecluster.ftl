[#-- COMPUTECLUSTER --]
[#if componentType == COMPUTECLUSTER_COMPONENT_TYPE]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]
        [#assign links = solution.Links ]

        [#assign dockerHost = solution.DockerHost]

        [#assign computeClusterRoleId               = resources["role"].Id ]
        [#assign computeClusterInstanceProfileId    = resources["instanceProfile"].Id ]
        [#assign computeClusterAutoScaleGroupId     = resources["autoScaleGroup"].Id ]
        [#assign computeClusterAutoScaleGroupName   = resources["autoScaleGroup"].Name ]
        [#assign computeClusterLaunchConfigId       = resources["launchConfig"].Id ]
        [#assign computeClusterSecurityGroupId      = resources["securityGroup"].Id ]
        [#assign computeClusterSecurityGroupName    = resources["securityGroup"].Name ]
        [#assign computeClusterLogGroupId           = resources["lg"].Id]
        [#assign computeClusterLogGroupName         = resources["lg"].Name]

        [#assign logFileProfile = getLogFileProfile(tier, component, "ComputeCluster")]
        [#assign bootstrapProfile = getBootstrapProfile(tier, component, "ComputeCluster")]
        [#assign storageProfile = getStorage(tier, component, "ComputeCluster")]
        [#assign processorProfile = getProcessor(occurrence, "ComputeCluster")]

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

        [#assign computeAutoScaleGroupTags =
                getCfTemplateCoreTags(
                        computeClusterAutoScaleGroupName,
                        tier,
                        component,
                        "",
                        true)]

        [#assign targetGroupPermission = false ]
        [#assign targetGroups = [] ]
        [#assign loadBalancers = [] ]
        [#assign environmentVariables = {}]

        [#assign configSetName = componentType]

        [#assign ingressRules = []]

        [#list solution.Ports?values as port ]
            [#if port.LB.Configured]
                [#assign lbLink = getLBLink(occurrence, port)]
                [#if isDuplicateLink(links, lbLink) ]
                    [@cfException
                        mode=listMode
                        description="Duplicate Link Name"
                        context=links
                        detail=lbLink /]
                    [#continue]
                [/#if]
                [#assign links += lbLink]
            [#else]
                [#assign portCIDRs = getGroupCIDRs(port.IPAddressGroups, true, occurrence) ]
                [#if portCIDRs?has_content]
                    [#assign ingressRules +=
                        [{
                            "Port" : port.Name,
                            "CIDR" : portCIDRs
                        }]]
                [/#if]
            [/#if]
        [/#list]

        [#assign configSets =
                getInitConfigDirectories() +
                getInitConfigBootstrap(component.Role!"") ]

        [#assign scriptsPath =
                formatRelativePath(
                getRegistryEndPoint("scripts", occurrence),
                getRegistryPrefix("scripts", occurrence),
                productName,
                getOccurrenceBuildUnit(occurrence),
                getOccurrenceBuildReference(occurrence)
                ) ]

        [#assign scriptsFile =
            formatRelativePath(
                scriptsPath,
                "scripts.zip"
            )
        ]

        [#assign fragment =
            contentIfContent(solution.Fragment, getComponentId(component)) ]

        [#assign contextLinks = getLinkTargets(occurrence, links) ]
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
                isPartOfCurrentDeploymentUnit(computeClusterRoleId)]
            [@createRole
                mode=listMode
                id=computeClusterRoleId
                trustedServices=["ec2.amazonaws.com" ]
                policies=
                    [
                        getPolicyDocument(
                            s3ReadPermission(
                                formatRelativePath(
                                    getRegistryEndPoint("scripts", occurrence),
                                    getRegistryPrefix("scripts", occurrence) ) )+
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
            [#assign linkTarget = getLinkTarget(occurrence, link) ]

            [@cfDebug listMode linkTarget false /]

            [#if !linkTarget?has_content]
                [#continue]
            [/#if]

            [#assign linkTargetCore = linkTarget.Core ]
            [#assign linkTargetConfiguration = linkTarget.Configuration ]
            [#assign linkTargetResources = linkTarget.State.Resources ]
            [#assign linkTargetAttributes = linkTarget.State.Attributes ]

            [#assign sourceSecurityGroupIds = []]
            [#assign sourceIPAddressGroups = [] ]

            [#switch linkTargetCore.Type]
                [#case LB_PORT_COMPONENT_TYPE]
                    [#assign targetGroupPermission = true]
                    [#assign destinationPort = linkTargetAttributes["DESTINATION_PORT"]]

                    [#switch linkTargetAttributes["ENGINE"] ]
                        [#case "application" ]
                        [#case "classic"]
                            [#assign sourceSecurityGroupIds += [ linkTargetResources["sg"].Id ] ]
                            [#break]
                        [#case "network" ]
                            [#assign sourceIPAddressGroups = linkTargetConfiguration.IPAddressGroups + [ "_localnet" ] ]
                            [#break]
                    [/#switch]

                    [#switch linkTargetAttributes["ENGINE"]]

                        [#case "application"]
                        [#case "network"]
                            [#assign targetGroups += [ linkTargetAttributes["TARGET_GROUP_ARN"] ] ]
                            [#break]

                        [#case "classic" ]
                            [#assign lbId = linkTargetAttributes["LB"] ]
                            [#-- Classic ELB's register the instance so we only need 1 registration --]
                            [#assign loadBalancers += [ getExistingReference(lbId) ]]
                            [#break]
                        [/#switch]
                    [#break]
                [#case EFS_MOUNT_COMPONENT_TYPE]
                    [#assign configSets +=
                        getInitConfigEFSMount(
                            linkTargetCore.Id,
                            linkTargetAttributes.EFS,
                            linkTargetAttributes.DIRECTORY,
                            link.Id
                        )]
                    [#break]
            [/#switch]

            [#if deploymentSubsetRequired(COMPUTECLUSTER_COMPONENT_TYPE, true)]

                [#assign securityGroupCIDRs = getGroupCIDRs(sourceIPAddressGroups, true, occurrence)]
                [#list securityGroupCIDRs as cidr ]

                    [@createSecurityGroupIngress
                        mode=listMode
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
                        mode=listMode
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

        [#assign configSets += getInitConfigScriptsDeployment(scriptsFile, environmentVariables, solution.UseInitAsService, false)]

        [#if deploymentSubsetRequired("lg", true) && isPartOfCurrentDeploymentUnit(computeClusterLogGroupId) ]
            [@createLogGroup
                mode=listMode
                id=computeClusterLogGroupId
                name=computeClusterLogGroupName /]
        [/#if]

        [#assign configSets +=
            getInitConfigLogAgent(
                logFileProfile,
                computeClusterLogGroupName
            )]

        [#if deploymentSubsetRequired(COMPUTECLUSTER_COMPONENT_TYPE, true)]

            [@createSecurityGroup
                mode=listMode
                tier=tier
                component=component
                id=computeClusterSecurityGroupId
                name=computeClusterSecurityGroupName
                vpcId=vpcId /]

            [#list ingressRules as rule ]
                [@createSecurityGroupIngress
                        mode=listMode
                        id=formatDependentSecurityGroupIngressId(
                            computeClusterSecurityGroupId,
                            rule.Port)
                        port=rule.Port
                        cidr=rule.CIDR
                        groupId=computeClusterSecurityGroupId /]
            [/#list]

            [@cfResource
                mode=listMode
                id=computeClusterInstanceProfileId
                type="AWS::IAM::InstanceProfile"
                properties=
                    {
                        "Path" : "/",
                        "Roles" : [getReference(computeClusterRoleId)]
                    }
                outputs={}
            /]


            [#assign autoScalingConfig = solution.AutoScaling + {
                                                "WaitForSignal" : (solution.UseInitAsService != true)
                                        }]

            [@createEc2AutoScaleGroup
                mode=listMode
                id=computeClusterAutoScaleGroupId
                tier=tier
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

            [#assign imageId = dockerHost?then(
                regionObject.AMIs.Centos.ECS,
                regionObject.AMIs.Centos.EC2
            )]

            [@createEC2LaunchConfig
                mode=listMode
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
            /]
        [/#if]
    [/#list]
[/#if]
