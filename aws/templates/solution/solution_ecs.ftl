[#-- ECS --]
[#if componentType == "ecs"]
    [#assign ecs = component.ECS]
    [#assign ecsId = formatECSId(tier, component)]
    [#assign ecsFullName = componentFullName]
    [#assign ecsRoleId = formatECSRoleId(tier, component)]
    [#assign ecsServiceRoleId = formatECSServiceRoleId(tier, component)]
    [#assign ecsInstanceProfileId = formatEC2InstanceProfileId(tier, component)]
    [#assign ecsAutoScaleGroupId = formatEC2AutoScaleGroupId(tier, component)]
    [#assign ecsLaunchConfigId = formatEC2LaunchConfigId(tier, component)]
    [#assign ecsSecurityGroupId = formatComponentSecurityGroupId(tier, component)]

    [@createComponentSecurityGroup
        mode=solutionListMode
        tier=tier
        component=component /]
        
    [@createComponentLogGroup tier component/]

    [#assign processorProfile = getProcessor(tier, component, "ECS")]
    [#assign maxSize = processorProfile.MaxPerZone]
    [#if multiAZ]
        [#assign maxSize = maxSize * zones?size]
    [/#if]
    [#assign storageProfile = getStorage(tier, component, "ECS")]
    [#assign fixedIP = ecs.FixedIP?? && ecs.FixedIP]
    [#assign defaultLogDriver = ecs.LogDriver!"awslogs"]
    
    [@cfTemplate
        mode=solutionListMode
        id=ecsId
        type="AWS::ECS::Cluster"
    /]
    
    [@createRole
        mode=solutionListMode
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
                    formatName(tierId, componentId, "docker"))
            ]
    /]

    [@cfTemplate
        mode=solutionListMode
        id=ecsInstanceProfileId
        type="AWS::IAM::InstanceProfile"
        properties=
            {
                "Path" : "/",
                "Roles" : [getReference(ecsRoleId)]
            }
        outputs={}
    /]

    [@createRole
        mode=solutionListMode
        id=ecsServiceRoleId
        trustedServices=["ecs.amazonaws.com" ]
        managedArns=["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"]
    /]

    [#assign allocationIds = [] ]
    [#if fixedIP]
        [#list 1..maxSize as index]
            [@createEIP
                mode=solutionListMode
                id=formatComponentEIPId(tier, component, index)
            /]
            [#assign allocationIds +=
                [
                    getReference(formatComponentEIPId(tier, component, index), ALLOCATION_ATTRIBUTE_TYPE)
                ]
            ]
        [/#list]
    [/#if]

    [@cfTemplate
        mode=solutionListMode
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
                                "aws-cli" : []
                            }
                        },
                        "files" : {
                            "/etc/codeontap/facts.sh" : {
                                "content" : {
                                    "Fn::Join" : [
                                        "",
                                        [
                                            "#!/bin/bash\\n",
                                            "echo \\\"cot:request="       + requestReference       + "\\\"\\n",
                                            "echo \\\"cot:configuration=" + configurationReference + "\\\"\\n",
                                            "echo \\\"cot:accountRegion=" + accountRegionId        + "\\\"\\n",
                                            "echo \\\"cot:tenant="        + tenantId               + "\\\"\\n",
                                            "echo \\\"cot:account="       + accountId              + "\\\"\\n",
                                            "echo \\\"cot:product="       + productId              + "\\\"\\n",
                                            "echo \\\"cot:region="        + regionId               + "\\\"\\n",
                                            "echo \\\"cot:segment="       + segmentId              + "\\\"\\n",
                                            "echo \\\"cot:environment="   + environmentId          + "\\\"\\n",
                                            "echo \\\"cot:tier="          + tierId                 + "\\\"\\n",
                                            "echo \\\"cot:component="     + componentId            + "\\\"\\n",
                                            "echo \\\"cot:role="          + component.Role         + "\\\"\\n",
                                            "echo \\\"cot:credentials="   + credentialsBucket      + "\\\"\\n",
                                            "echo \\\"cot:code="          + codeBucket             + "\\\"\\n",
                                            "echo \\\"cot:logs="          + operationsBucket       + "\\\"\\n",
                                            "echo \\\"cot:backups="       + dataBucket             + "\\\"\\n"
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
                                            "#!/bin/bash -ex\\n",
                                            "exec > >(tee /var/log/codeontap/fetch.log|logger -t codeontap-fetch -s 2>/dev/console) 2>&1\\n",
                                            "REGION=$(/etc/codeontap/facts.sh | grep cot:accountRegion | cut -d '=' -f 2)\\n",
                                            "CODE=$(/etc/codeontap/facts.sh | grep cot:code | cut -d '=' -f 2)\\n",
                                            "aws --region " + r"${REGION}" + " s3 sync s3://" + r"${CODE}" + "/bootstrap/centos/ /opt/codeontap/bootstrap && chmod 0500 /opt/codeontap/bootstrap/*.sh\\n"
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
                        allocationIds?has_content?then(
                            {
                                "03AssignIP" : {
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
                                }
                            },
                            {}
                        )
                    },
                    "ecs": {
                        "commands":
                            (defaultLogDriver == "fluentd")?then(
                                {
                                    "01Fluentd" : {
                                        "command" : "/opt/codeontap/bootstrap/fluentd.sh",
                                        "ignoreErrors" : "false"
                                    }
                                },
                                {}
                            ) +
                            {
                                "02ConfigureCluster" : {
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
                ecsFullName,
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

    [@cfTemplate
        mode=solutionListMode
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
                "AssociatePublicIpAddress" : (tier.RouteTable == "external"),
                "UserData" : {
                    "Fn::Base64" : {
                        "Fn::Join" : [
                            "",
                            [
                                "#!/bin/bash -ex\\n",
                                "exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1\\n",
                                "yum install -y aws-cfn-bootstrap\\n",
                                "# Remainder of configuration via metadata\\n",
                                "/opt/aws/bin/cfn-init -v",
                                "         --stack ", { "Ref" : "AWS::StackName" },
                                "         --resource ", ecsAutoScaleGroupId,
                                "         --region ", regionId, " --configsets ", configSet, "\\n"
                            ]
                        ]
                    }
                }
            }
        outputs={}
    /]
[/#if]
