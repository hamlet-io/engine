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

    [@createComponentSecurityGroup solutionListMode tier component /]

    [#assign processorProfile = getProcessor(tier, component, "ECS")]
    [#assign maxSize = processorProfile.MaxPerZone]
    [#if multiAZ]
        [#assign maxSize = maxSize * zones?size]
    [/#if]
    [#assign storageProfile = getStorage(tier, component, "ECS")]
    [#assign fixedIP = ecs.FixedIP?? && ecs.FixedIP]
    

    [#if resourceCount > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
            "${ecsId}" : {
                "Type" : "AWS::ECS::Cluster"
            },

                [@roleHeader
                    ecsRoleId
                    ["ec2.amazonaws.com" ]
                    ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"]
                /]
                    [@policyHeader formatName(tierId, componentId, "docker") /]
                        [@s3ReadStatement credentialsBucket accountId + "/alm/docker" /]
                        [#if fixedIP]
                            [@IPAddressUpdateStatement /]
                        [/#if]
                        [@s3ListStatement codeBucket /]
                        [@s3ReadStatement codeBucket /]
                        [@s3ListStatement operationsBucket /]
                        [@s3WriteStatement operationsBucket getSegmentBackupsFilePrefix() /]
                        [@s3WriteStatement operationsBucket "DOCKERLogs" /]
                    [@policyFooter /]
                [@roleFooter /],

            "${ecsInstanceProfileId}" : {
                "Type" : "AWS::IAM::InstanceProfile",
                "Properties" : {
                    "Path" : "/",
                    "Roles" : [ { "Ref" : "${ecsRoleId}" } ]
                }
            },

            [@role
                ecsServiceRoleId
                ["ecs.amazonaws.com" ]
                ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"]
            /],

            [#if fixedIP]
                [#list 1..maxSize as index]
                    "${formatComponentEIPId(tier, component, index)}": {
                        "Type" : "AWS::EC2::EIP",
                        "Properties" : {
                            "Domain" : "vpc"
                        }
                    },
                [/#list]
            [/#if]

            "${ecsAutoScaleGroupId}": {
                "Type": "AWS::AutoScaling::AutoScalingGroup",
                "Metadata": {
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
                                                "#!/bin/bash\n",
                                                "echo \"cot:request=${requestReference}\"\n",
                                                "echo \"cot:configuration=${configurationReference}\"\n",
                                                "echo \"cot:accountRegion=${accountRegionId}\"\n",
                                                "echo \"cot:tenant=${tenantId}\"\n",
                                                "echo \"cot:account=${accountId}\"\n",
                                                "echo \"cot:product=${productId}\"\n",
                                                "echo \"cot:region=${regionId}\"\n",
                                                "echo \"cot:segment=${segmentId}\"\n",
                                                "echo \"cot:environment=${environmentId}\"\n",
                                                "echo \"cot:tier=${tierId}\"\n",
                                                "echo \"cot:component=${componentId}\"\n",
                                                "echo \"cot:role=${component.Role}\"\n",
                                                "echo \"cot:credentials=${credentialsBucket}\"\n",
                                                "echo \"cot:code=${codeBucket}\"\n",
                                                "echo \"cot:logs=${operationsBucket}\"\n",
                                                "echo \"cot:backup=${dataBucket}\"\n"
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
                                                "REGION=$(/etc/codeontap/facts.sh | grep cot:accountRegion= | cut -d '=' -f 2)\n",
                                                "CODE=$(/etc/codeontap/facts.sh | grep cot:code= | cut -d '=' -f 2)\n",
                                                "aws --region ${r"${REGION}"} s3 sync s3://${r"${CODE}"}/bootstrap/centos/ /opt/codeontap/bootstrap && chmod 0755 /opt/codeontap/bootstrap/*.sh\n"
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
                                [#if fixedIP]
                                    ,"03AssignIP" : {
                                        "command" : "/opt/codeontap/bootstrap/eip.sh",
                                        "env" : {
                                            "EIP_ALLOCID" : {
                                                "Fn::Join" : [
                                                    " ",
                                                    [
                                                        [#list 1..maxSize as index]
                                                            { "Fn::GetAtt" : [
                                                                "${formatComponentEIPId(
                                                                    tier,
                                                                    component,
                                                                    index)}",
                                                                "AllocationId"] }
                                                            [#if index != maxSize],[/#if]
                                                        [/#list]
                                                    ]
                                                ]
                                            }
                                        },
                                        "ignoreErrors" : "false"
                                    }
                                [/#if]
                                }
                            },
                            "ecs": {
                                "commands": {
                                    "01Fluentd" : {
                                        "command" : "/opt/codeontap/bootstrap/fluentd.sh",
                                        "ignoreErrors" : "false"
                                    },
                                    "02ConfigureCluster" : {
                                        "command" : "/opt/codeontap/bootstrap/ecs.sh",
                                        "env" : {
                                        "ECS_CLUSTER" : { "Ref" : "${ecsId}" },
                                        "ECS_LOG_DRIVER" : "fluentd"
                                    },
                                    "ignoreErrors" : "false"
                                }
                            }
                        }
                    }
                },
                "Properties": {
                    "Cooldown" : "30",
                    "LaunchConfigurationName": {"Ref": "${ecsLaunchConfigId}"},
                    [#if multiAZ]
                        "MinSize": "${processorProfile.MinPerZone * zones?size}",
                        "MaxSize": "${maxSize}",
                        "DesiredCapacity": "${processorProfile.DesiredPerZone * zones?size}",
                        "VPCZoneIdentifier": [
                            [#list zones as zone]
                                "${getKey(formatSubnetId(tier, zone))}"
                                [#if !(zones?last.Id == zone.Id)],[/#if]
                            [/#list]
                        ],
                    [#else]
                        "MinSize": "${processorProfile.MinPerZone}",
                        "MaxSize": "${maxSize}",
                        "DesiredCapacity": "${processorProfile.DesiredPerZone}",
                        "VPCZoneIdentifier" : ["${getKey(formatSubnetId(tier, zones[0]))}"],
                    [/#if]
                    "Tags" : [
                        { "Key" : "cot:request", "Value" : "${requestReference}", "PropagateAtLaunch" : "True" },
                        { "Key" : "cot:configuration", "Value" : "${configurationReference}", "PropagateAtLaunch" : "True" },
                        { "Key" : "cot:tenant", "Value" : "${tenantId}", "PropagateAtLaunch" : "True" },
                        { "Key" : "cot:account", "Value" : "${accountId}", "PropagateAtLaunch" : "True" },
                        { "Key" : "cot:product", "Value" : "${productId}", "PropagateAtLaunch" : "True" },
                        { "Key" : "cot:segment", "Value" : "${segmentId}", "PropagateAtLaunch" : "True" },
                        { "Key" : "cot:environment", "Value" : "${environmentId}", "PropagateAtLaunch" : "True" },
                        { "Key" : "cot:category", "Value" : "${categoryId}", "PropagateAtLaunch" : "True" },
                        { "Key" : "cot:tier", "Value" : "${tierId}", "PropagateAtLaunch" : "True" },
                        { "Key" : "cot:component", "Value" : "${componentId}", "PropagateAtLaunch" : "True"},
                        { "Key" : "Name", "Value" : "${ecsFullName}", "PropagateAtLaunch" : "True" }
                    ]
                }
            },

            "${ecsLaunchConfigId}": {
                "Type": "AWS::AutoScaling::LaunchConfiguration",
                "Properties": {
                    "KeyName": "${productName + sshPerSegment?string("-" + segmentName,"")}",
                    "ImageId": "${regionObject.AMIs.Centos.ECS}",
                    "InstanceType": "${processorProfile.Processor}",
                    [@createBlockDevices storageProfile=storageProfile /]
                    "SecurityGroups" : [
                                        {"Ref" : "${ecsSecurityGroupId}"}
                                        [#if securityGroupNAT?has_content], "${securityGroupNAT}"[/#if] 
                    ],
                    "IamInstanceProfile" : { "Ref" : "${ecsInstanceProfileId}" },
                    "AssociatePublicIpAddress" : ${(tier.RouteTable == "external")?string("true","false")},
                    [#if (processorProfile.ConfigSet)??]
                        [#assign configSet = processorProfile.ConfigSet]
                    [#else]
                        [#assign configSet = "ecs"]
                    [/#if]
                    "UserData" : {
                        "Fn::Base64" : {
                            "Fn::Join" : [
                                "",
                                [
                                    "#!/bin/bash -ex\n",
                                    "exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1\n",
                                    "yum install -y aws-cfn-bootstrap\n",
                                    "# Remainder of configuration via metadata\n",
                                    "/opt/aws/bin/cfn-init -v",
                                    "         --stack ", { "Ref" : "AWS::StackName" },
                                    "         --resource ${ecsAutoScaleGroupId}",
                                    "         --region ${regionId} --configsets ${configSet}\n"
                                ]
                            ]
                        }
                    }
                }
            }
            [#break]

        [#case "outputs"]
            [@output ecsId /],
            [@output ecsRoleId /],
            [@outputArn ecsRoleId /],
            [@output ecsServiceRoleId /],
            [@outputArn ecsServiceRoleId /]
            [#if fixedIP]
                [#list 1..maxSize as index]
                    [#assign ecsEIPId = formatComponentEIPId(
                                            tier,
                                            component,
                                            index)]
                    ,[@outputIPAddress ecsEIPId /]
                    ,[@outputAllocation ecsEIPId /]
                [/#list]
            [/#if]
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]