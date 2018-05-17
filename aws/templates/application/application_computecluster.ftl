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

        [#assign computeClusterRoleId = resources["role"].Id ]
        [#assign computeClusterInstanceProfileId = resources["instanceProfile"].Id ]
        [#assign computeClusterAutoScaleGroupId = resources["autoScaleGroup"].Id ]
        [#assign computeClusterLaunchConfigId = resources["launchConfig"].Id ]
        [#assign computeClusterSecurityGroupId = resources["securityGroup"].Id ]
        [#assign computeClusterLogGroupId = resources["lg"].Id ]
        [#assign computeClusterLogGroupName = resources["lg"].Name ]

        [#assign targetGroupPermission = false ]

        [#assign buildUnit = getOccurrenceBuildUnit(occurrence, true) ]
        [#assign buildReference = getOccurrenceBuildReference(occurrence, true) ]

        [#assign configSets = {} ]
        [#assign configSets +=  
                getInitConfigDirectories() + 
                getInitConfigBootstrap(component.Role!"") ]

        [#assign scriptsPath =
                formatAbsolutePath(
                getRegistryPrefix("scripts", occurrence),
                productName,
                buildUnit,
                buildReference
                ) ]   

        [#assign scriptsUrl = 
            "https://" +
            formatRelativePath(
                getExistingReference(formatAccountS3Id("registry"),DNS_ATTRIBUTE_TYPE),
                scriptsPath,
                "scripts.zip"
            )
        ]

        [#assign configSets += getInitConfigScriptsDeployment(scriptsUrl) ]

        [#assign ingressRules = []]

        [#list solution.Ports?values as port ]
            [#if port.LB.Configured]
                [#assign links += getLBLink(occurrence, port)]
            [#else]
                [#assign portCIDRs = getGroupCIDRs(port.IPAddressGroups) ]
                [#if portCIDRs?has_content]
                    [#assign ingressRules +=
                        [{
                            "Port" : port.Name,
                            "CIDR" : portCIDRs
                        }]]
                [/#if]
            [/#if]
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
                            s3ReadPermission(registryBucket + scriptsPath) +
                            s3ListPermission(codeBucket) +
                            s3ReadPermission(codeBucket) +
                            s3ListPermission(operationsBucket) +
                            s3WritePermission(operationsBucket, "DOCKERLogs") +
                            s3WritePermission(operationsBucket, "Backups"),
                            "basic")
                    ] + targetGroupPermission?then(
                        [
                            getPolicyDocument(
                                lbRegisterTargetPermission(),
                                "loadbalancing")
                        ],
                        [])
            /]
        
        [/#if]
    
        [#if solution.ClusterLogGroup &&
                deploymentSubsetRequired("lg", true) &&
                isPartOfCurrentDeploymentUnit(computeClusterLogGroupId)]
            [@createLogGroup 
                mode=listMode
                id=computeClusterLogGroupId
                name=computeClusterLogGroupName /]
        [/#if]
            
        [#list links?values as link]
            [#assign linkTarget = getLinkTarget(occurrence, link) ]

            [@cfDebug listMode linkTarget true /]

            [#if !linkTarget?has_content]
                [#continue]
            [/#if]

            [#assign linkTargetCore = linkTarget.Core ]
            [#assign linkTargetConfiguration = linkTarget.Configuration ]
            [#assign linkTargetResources = linkTarget.State.Resources ]
            [#assign linkTargetAttributes = linkTarget.State.Attributes ]

            [#switch linkTargetCore.Type]
                [#case LB_PORT_COMPONENT_TYPE]
                    [#assign targetGroupPermission = true]

                    [#switch linkTargetAttributes["ENGINE"]]

                        [#case "application"]
                        [#case "network"]
                            [#if link.TargetGroup?has_content ]
                                [#assign targetId = (linkTargetResources["targetgroups"][link.TargetGroup].Id) ]
                                [#if targetId?has_content]

                                    [#if deploymentSubsetRequired(COMPUTECLUSTER_COMPONENT_TYPE, true)]
                                        [#if isPartOfCurrentDeploymentUnit(targetId)]

                                            [@createTargetGroup
                                                mode=listMode
                                                id=targetId
                                                name=formatName(linkTargetCore.FullName,link.TargetGroup)
                                                tier=link.Tier
                                                component=link.Component
                                                destination=ports[link.Port]
                                            /]
                                            [#assign listenerRuleId = formatALBListenerRuleId(occurrence, link.TargetGroup) ]
                                            [@createListenerRule
                                                mode=listMode
                                                id=listenerRuleId
                                                listenerId=linkTargetResources["listener"].Id
                                                actions=getListenerRuleForwardAction(targetId)
                                                conditions=getListenerRulePathCondition(link.TargetPath)
                                                priority=link.Priority!100
                                                dependencies=targetId
                                            /]

                                            [#assign componentDependencies += [targetId]]

                                        [/#if]
                                        [#assign configSets += getInitConfigLBTargetRegistration(targetId) ]
                                    [/#if]
                                [/#if]
                            [/#if]
                            [#break]

                        [#case "classic" ]
                            [#assign lbId =  linkTargetAttributes["LB"] ]
                            [#assign configSets +=  getInitConfigLBClassicRegistration(lbId) ]
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
        [/#list]

        [#if deploymentSubsetRequired(COMPUTECLUSTER_COMPONENT_TYPE, true)]

            [@createComponentSecurityGroup
                mode=listMode
                tier=tier
                component=component /]
    
            [#assign processorProfile = getProcessor(tier, component, "ComputeCluster")]
            [#assign maxSize = processorProfile.MaxPerZone]
            [#if multiAZ]
                [#assign maxSize = maxSize * zones?size]
            [/#if]
            [#assign storageProfile = getStorage(tier, component, "ComputeCluster")]

        
            
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

            [@cfResource
                mode=listMode
                id=computeClusterAutoScaleGroupId
                type="AWS::AutoScaling::AutoScalingGroup"
                metadata=getInitConfig(componentType, configSets )
                properties=
                    {
                        "Cooldown" : "30",
                        "LaunchConfigurationName": getReference(computeClusterLaunchConfigId)
                    } +
                    multiAZ?then(
                        {
                            "MinSize": processorProfile.MinPerZone * zones?size,
                            "MaxSize": maxSize,
                            "DesiredCapacity": processorProfile.DesiredPerZone * zones?size,
                            "VPCZoneIdentifier": getSubnets(tier)
                        },
                        {
                            "MinSize": processorProfile.MinPerZone,
                            "MaxSize": maxSize,
                            "DesiredCapacity": processorProfile.DesiredPerZone,
                            "VPCZoneIdentifier" : getSubnets(tier)[0..0]
                        }
                    )
                tags=
                    getCfTemplateCoreTags(
                        formatComponentFullName(tier, component, zone),
                        tier,
                        component,
                        "",
                        true)
                outputs={}
            /]
                    
        
            [#assign imageId = dockerHost?then(
                { "ImageId" : regionObject.AMIs.Centos.ECS},
                { "ImageId" : regionObject.AMIs.Centos.EC2}
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
                routeTable=tier.Network.RouteTable
                configSet=componentType
                environmentId=environmentId
            /]
        [/#if]
    [/#list]
[/#if]
