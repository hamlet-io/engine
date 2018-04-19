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
        [#assign ecsClusterWideStorage = solution.ClusterWideStorage ]
    
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
    
        [#assign ecsEFSVolumeId = formatEFSId(tier, component)]
        [#if ecsClusterWideStorage &&
            deploymentSubsetRequired("efs", true) &&
            isPartOfCurrentDeploymentUnit(ecsEFSVolumeId) ]
    
            [#assign ecsEFSVolumeName = formatComponentFullName( tier, component )]
            [#assign ecsEFSSecurityGroupId = formatComponentSecurityGroupId( tier, component,"efs")]
            [#assign ecsEFSIngressSecurityGroupId = formatDependentSecurityGroupIngressId(ecsEFSSecurityGroupId) ]
    
            [@createComponentSecurityGroup
                mode=listMode
                tier=tier
                component=component 
                extensions="efs"
                /]
            
            [@createSecurityGroupIngress
                mode=listMode
                id=ecsEFSIngressSecurityGroupId
                port="any"
                cidr=ecsSecurityGroupId
                groupId=ecsEFSSecurityGroupId
            /]
    
            [@createEFS 
                mode=listMode
                tier=tier
                id=ecsEFSVolumeId
                name=ecsEFSVolumeName
                component=component
            /]
    
            [@createEFSMountTarget
                mode=listMode
                tier=tier
                efsId=ecsEFSVolumeId
                securityGroups=ecsEFSSecurityGroupId
            /]
        
        [/#if]
            
        [#if deploymentSubsetRequired("ecs", true)]
    
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
        
            [@cfResource
                mode=listMode
                id=ecsAutoScaleGroupId
                type="AWS::AutoScaling::AutoScalingGroup"
                metadata=
                    {
                        "AWS::CloudFormation::Init": {
                            "configSets" : {
                                "ecs" : ["dirs", "bootstrap", "ecs"]
                            },
                            "dirs": {
                                "commands": {
                                    "01Directories" : {
                                        "command" : "mkdir --parents --mode=0755 /etc/codeontap && mkdir --parents --mode=0755 /opt/codeontap/bootstrap && mkdir --parents --mode=0755 /var/log/codeontap",
                                        "ignoreErrors" : "false"
                                    }
                                }
                            },
                            "bootstrap": {
                                "packages" : {
                                    "yum" : {
                                        "aws-cli" : [],
                                        "nfs-utils" : []
                                    }
                                },
                                "files" : {
                                    "/etc/codeontap/facts.sh" : {
                                        "content" : {
                                            "Fn::Join" : [
                                                "",
                                                [
                                                    "#!/bin/bash\n",
                                                    "echo \"cot:request="       + requestReference       + "\"\n",
                                                    "echo \"cot:configuration=" + configurationReference + "\"\n",
                                                    "echo \"cot:accountRegion=" + accountRegionId        + "\"\n",
                                                    "echo \"cot:tenant="        + tenantId               + "\"\n",
                                                    "echo \"cot:account="       + accountId              + "\"\n",
                                                    "echo \"cot:product="       + productId              + "\"\n",
                                                    "echo \"cot:region="        + regionId               + "\"\n",
                                                    "echo \"cot:segment="       + segmentId              + "\"\n",
                                                    "echo \"cot:environment="   + environmentId          + "\"\n",
                                                    "echo \"cot:tier="          + tierId                 + "\"\n",
                                                    "echo \"cot:component="     + componentId            + "\"\n",
                                                    "echo \"cot:role="          + component.Role         + "\"\n",
                                                    "echo \"cot:credentials="   + credentialsBucket      + "\"\n",
                                                    "echo \"cot:code="          + codeBucket             + "\"\n",
                                                    "echo \"cot:logs="          + operationsBucket       + "\"\n",
                                                    "echo \"cot:backups="       + dataBucket             + "\"\n"
                                                ]
                                            ]
                                        },
                                        "mode" : "000755"
                                    },
                                    "/opt/codeontap/bootstrap/fetch.sh" : {
                                        "content" : {
                                            "Fn::Join" : [
                                                "",
                                                [
                                                    "#!/bin/bash -ex\n",
                                                    "exec > >(tee /var/log/codeontap/fetch.log|logger -t codeontap-fetch -s 2>/dev/console) 2>&1\n",
                                                    "REGION=$(/etc/codeontap/facts.sh | grep cot:accountRegion | cut -d '=' -f 2)\n",
                                                    "CODE=$(/etc/codeontap/facts.sh | grep cot:code | cut -d '=' -f 2)\n",
                                                    "aws --region " + r"${REGION}" + " s3 sync s3://" + r"${CODE}" + "/bootstrap/centos/ /opt/codeontap/bootstrap && chmod 0500 /opt/codeontap/bootstrap/*.sh\n"
                                                ]
                                            ]
                                        },
                                        "mode" : "000755"
                                    }
                                },
                                "commands": {
                                    "01Fetch" : {
                                        "command" : "/opt/codeontap/bootstrap/fetch.sh",
                                        "ignoreErrors" : "false"
                                    },
                                    "02Initialise" : {
                                        "command" : "/opt/codeontap/bootstrap/init.sh",
                                        "ignoreErrors" : "false"
                                    }
                                } +
                                attributeIfContent(
                                    "03AssignIP",
                                    allocationIds,
                                    {
                                        "command" : "/opt/codeontap/bootstrap/eip.sh",
                                        "env" : {
                                            "EIP_ALLOCID" : {
                                                "Fn::Join" : [
                                                    " ",
                                                    allocationIds
                                                ]
                                            }
                                        },
                                        "ignoreErrors" : "false"
                                    })
                            },
                            "ecs": {
                                "commands":
                                    attributeIfTrue(
                                        "01Fluentd",
                                        defaultLogDriver == "fluentd",
                                        {
                                            "command" : "/opt/codeontap/bootstrap/fluentd.sh",
                                            "ignoreErrors" : "false"
                                        }) +
                                    attributeIfTrue(
                                        "02ConfigureEFSClusterWide",
                                        ecsClusterWideStorage,
                                        {
                                            "command" : "/opt/codeontap/bootstrap/efs.sh",
                                            "env" : { 
                                                "EFS_FILE_SYSTEM_ID" : getReference(ecsEFSVolumeId),
                                                "EFS_MOUNT_PATH" : "/",
                                                "EFS_OS_MOUNT_PATH" : "/efs/clusterstorage"
                                            }
                                        }) +
                                    {
                                        "03ConfigureCluster" : {
                                            "command" : "/opt/codeontap/bootstrap/ecs.sh",
                                            "env" : {
                                                "ECS_CLUSTER" : getReference(ecsId),
                                                "ECS_LOG_DRIVER" : defaultLogDriver
                                            },
                                            "ignoreErrors" : "false"
                                        }
                                    }
                            }
                        }
                    }
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
                    
            [#if (processorProfile.ConfigSet)?has_content]
                [#assign configSet = processorProfile.ConfigSet]
            [#else]
                [#assign configSet = "ecs"]
            [/#if]
            
            [#assign updateCommand = "yum clean all && yum -y update"]
            [#assign dailyUpdateCron = 'echo \"59 13 * * * ${updateCommand} >> /var/log/update.log 2>&1\" >crontab.txt && crontab crontab.txt']
            [#if environmentId == "prod"]
                [#-- for production update only security packages --]
                [#assign updateCommand += " --security"]
                [#assign dailyUpdateCron = 'echo \"29 13 * * 6 ${updateCommand} >> /var/log/update.log 2>&1\" >crontab.txt && crontab crontab.txt']
            [/#if]
        
            [@cfResource
                mode=listMode
                id=ecsLaunchConfigId
                type="AWS::AutoScaling::LaunchConfiguration"
                properties=
                    getBlockDevices(storageProfile) +
                    {
                        "KeyName": productName + sshPerSegment?then("-" + segmentName,""),
                        "ImageId": regionObject.AMIs.Centos.ECS,
                        "InstanceType": processorProfile.Processor,
                        "SecurityGroups" : 
                            [
                                getReference(ecsSecurityGroupId)
                            ] +
                            sshFromProxySecurityGroup?has_content?then(
                                [
                                    sshFromProxySecurityGroup
                                ],
                                []
                            ),
                        "IamInstanceProfile" : getReference(ecsInstanceProfileId),
                        "AssociatePublicIpAddress" : (tier.Network.RouteTable == "external"),
                        "UserData" : {
                            "Fn::Base64" : {
                                "Fn::Join" : [
                                    "",
                                    [
                                        "#!/bin/bash -ex\n",
                                        "exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1\n",
                                        "# Install updates\n",
                                        updateCommand, "\n",
                                        dailyUpdateCron, "\n",
                                        "yum install -y aws-cfn-bootstrap\n",
                                        "# Remainder of configuration via metadata\n",
                                        "/opt/aws/bin/cfn-init -v",
                                        "         --stack ", { "Ref" : "AWS::StackName" },
                                        "         --resource ", ecsAutoScaleGroupId,
                                        "         --region ", regionId, " --configsets ", configSet, "\n"
                                    ]
                                ]
                            }
                        }
                    }
                outputs={}
            /]
        [/#if]
    [/#list]
[/#if]
