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
        [#assign defaultLogDriver = solution.LogDriver ]
        [#assign fixedIP = solution.FixedIP ]

        [#assign configSetName = componentType ]
        [#assign configSets =  
                getInitConfigDirectories() + 
                getInitConfigBootstrap(component.Role!"") +
                getInitConfigECSAgent(ecsId, defaultLogDriver) ]
        
        [#assign efsMountPoints = {}]
    
        [#if deploymentSubsetRequired("iam", true) &&
                isPartOfCurrentDeploymentUnit(ecsRoleId)]
            [@createRole
                mode=listMode
                id=ecsRoleId
                trustedServices=["ec2.amazonaws.com" ]
                managedArns=["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"]
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
                                s3WritePermission(operationsBucket, "DOCKERLogs"),
                            "docker")
                    ]
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
            
        [#if deploymentSubsetRequired("ecs", true)]
    
            [#list solution.Links?values as link]
                [#if link?is_hash]
                    [#assign linkTarget = getLinkTarget(occurrence, link) ]

                    [@cfDebug listMode linkTarget false /]

                    [#if !linkTarget?has_content]
                        [#continue]
                    [/#if]

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
                                    link.Id
                                )]
                            [#break]
                    [/#switch]
                [/#if]
            [/#list]

            [@createComponentSecurityGroup
                mode=listMode
                tier=tier
                component=component /]
    
            [#assign processorProfile = getProcessor(tier, component, "ECS")]
            [#assign maxSize = processorProfile.MaxPerZone]
            [#if multiAZ]
                [#assign maxSize = maxSize * zones?size]
            [/#if]
            [#assign storageProfile = getStorage(tier, component, "ECS")]
            
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
        
            [@cfResource
                mode=listMode
                id=ecsAutoScaleGroupId
                type="AWS::AutoScaling::AutoScalingGroup"
                metadata=getInitConfig(configSetName, configSets )
                properties=
                    {
                        "Cooldown" : "30",
                        "LaunchConfigurationName": getReference(ecsLaunchConfigId)
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
                        ecsName,
                        tier,
                        component,
                        "",
                        true)
                outputs={}
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
                enableCfnSignal=false
            /]
        [/#if]
    [/#list]
[/#if]
