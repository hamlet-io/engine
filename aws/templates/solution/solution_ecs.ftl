[#-- ECS --]
[#if componentType == "ecs"]
    [@securityGroup solutionListMode tier component /]
    [#assign ecs = component.ECS]
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
            "${formatId("ecs", tier.Id, component.Id)}" : {
                "Type" : "AWS::ECS::Cluster"
            },

            "${formatId("role", tier.Id, component.Id)}": {
                "Type" : "AWS::IAM::Role",
                "Properties" : {
                    "AssumeRolePolicyDocument" : {
                        "Version": "2012-10-17",
                        "Statement": [
                            {
                                "Effect": "Allow",
                                "Principal": { "Service": [ "ec2.amazonaws.com" ] },
                                "Action": [ "sts:AssumeRole" ]
                            }
                        ]
                    },
                    "Path": "/",
                    "ManagedPolicyArns" : ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"],
                    "Policies": [
                        {
                            "PolicyName": "${formatName(tier.Id, component.Id, "docker")}",
                            "PolicyDocument" : {
                                "Version": "2012-10-17",
                                "Statement": [
                                    {
                                        "Effect": "Allow",
                                        "Action": ["s3:GetObject"],
                                        "Resource": [
                                            "arn:aws:s3:::${credentialsBucket}/${accountId}/alm/docker/*"
                                        ]
                                    },
                                    [#if fixedIP]
                                        {
                                            "Effect" : "Allow",
                                            "Action" : [
                                                "ec2:DescribeAddresses",
                                                "ec2:AssociateAddress"
                                            ],
                                            "Resource": "*"
                                        },
                                    [/#if]
                                    {
                                        "Resource": [
                                            "arn:aws:s3:::${codeBucket}",
                                            "arn:aws:s3:::${operationsBucket}"
                                        ],
                                        "Action": [
                                            "s3:List*"
                                        ],
                                        "Effect": "Allow"
                                    },
                                    {
                                        "Resource": [
                                            "arn:aws:s3:::${codeBucket}/*"
                                        ],
                                        "Action": [
                                            "s3:GetObject"
                                        ],
                                        "Effect": "Allow"
                                    },
                                    {
                                        "Resource": [
                                            "arn:aws:s3:::${operationsBucket}/DOCKERLogs/*",
                                            "arn:aws:s3:::${operationsBucket}/Backups/*"
                                        ],
                                        "Action": [
                                            "s3:PutObject"
                                        ],
                                        "Effect": "Allow"
                                    }
                                ]
                            }
                        }
                    ]
                }
            },

            "${formatId("instanceProfile", tier.Id, component.Id)}" : {
                "Type" : "AWS::IAM::InstanceProfile",
                "Properties" : {
                    "Path" : "/",
                    "Roles" : [ { "Ref" : "${formatId("role", tier.Id, component.Id)}" } ]
                }
            },

            "${formatId("role", tier.Id, component.Id, "service")}": {
                "Type" : "AWS::IAM::Role",
                "Properties" : {
                    "AssumeRolePolicyDocument" : {
                        "Version": "2012-10-17",
                        "Statement": [
                            {
                                "Effect": "Allow",
                                "Principal": { "Service": [ "ecs.amazonaws.com" ] },
                                "Action": [ "sts:AssumeRole" ]
                            }
                        ]
                    },
                    "Path": "/",
                    "ManagedPolicyArns" : ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"]
                }
            },

            [#if fixedIP]
                [#list 1..maxSize as index]
                    "${formatId("eip", tier.Id, component.Id, index)}": {
                        "Type" : "AWS::EC2::EIP",
                        "Properties" : {
                            "Domain" : "vpc"
                        }
                    },
                [/#list]
            [/#if]

            "${formatId("asg", tier.Id, component.Id)}": {
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
                                                "echo \"cot:tier=${tier.Id}\"\n",
                                                "echo \"cot:component=${component.Id}\"\n",
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
                                                            { "Fn::GetAtt" : ["${formatId("eip", tier.Id, component.Id, index)}", "AllocationId"] }
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
                                        "ECS_CLUSTER" : { "Ref" : "${formatId("ecs", tier.Id, component.Id)}" },
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
                    "LaunchConfigurationName": {"Ref": "${formatId("launchConfig", tier.Id, component.Id)}"},
                    [#if multiAZ]
                        "MinSize": "${processorProfile.MinPerZone * zones?size}",
                        "MaxSize": "${maxSize}",
                        "DesiredCapacity": "${processorProfile.DesiredPerZone * zones?size}",
                        "VPCZoneIdentifier": [
                            [#list zones as zone]
                                "${getKey("subnet", tier.Id, zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
                            [/#list]
                        ],
                    [#else]
                        "MinSize": "${processorProfile.MinPerZone}",
                        "MaxSize": "${maxSize}",
                        "DesiredCapacity": "${processorProfile.DesiredPerZone}",
                        "VPCZoneIdentifier" : ["${getKey("subnet", tier.Id, zones[0].Id)}"],
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
                        { "Key" : "cot:tier", "Value" : "${tier.Id}", "PropagateAtLaunch" : "True" },
                        { "Key" : "cot:component", "Value" : "${component.Id}", "PropagateAtLaunch" : "True"},
                        { "Key" : "Name", "Value" : "${formatName(productName, segmentName, tier.Name, component.Name)}", "PropagateAtLaunch" : "True" }
                    ]
                }
            },

            "${formatId("launchConfig", tier.Id, component.Id)}": {
                "Type": "AWS::AutoScaling::LaunchConfiguration",
                "Properties": {
                    "KeyName": "${productName + sshPerSegment?string("-" + segmentName,"")}",
                    "ImageId": "${regionObject.AMIs.Centos.ECS}",
                    "InstanceType": "${processorProfile.Processor}",
                    [@createBlockDevices storageProfile=storageProfile /]
                    "SecurityGroups" : [ {"Ref" : "${formatId("securityGroup", tier.Id, component.Id)}"} [#if securityGroupNAT != "none"], "${securityGroupNAT}"[/#if] ],
                    "IamInstanceProfile" : { "Ref" : "${formatId("instanceProfile", tier.Id, component.Id)}" },
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
                                    "         --resource ${formatId("asg", tier.Id, component.Id)}",
                                    "         --region ${regionId} --configsets ${configSet}\n"
                                ]
                            ]
                        }
                    }
                }
            }
            [#break]

        [#case "outputs"]
            "${formatId("ecs", tier.Id, component.Id)}" : {
                "Value" : { "Ref" : "${formatId("ecs", tier.Id, component.Id)}" }
            },
            "${formatId("role", tier.Id, component.Id)}" : {
                "Value" : { "Ref" : "${formatId("role", tier.Id, component.Id)}" }
            },
            "${formatId("role", tier.Id, component.Id, "arn")}" : {
                "Value" : { "Fn::GetAtt" : ["${formatId("role", tier.Id, component.Id)}", "Arn"] }
            },
            "${formatId("role", tier.Id, component.Id, "service")}" : {
                "Value" : { "Ref" : "${formatId("role", tier.Id, component.Id, "service")}" }
            },
            "${formatId("role", tier.Id, component.Id, "service", "arn")}" : {
                "Value" : { "Fn::GetAtt" : ["${formatId("role", tier.Id, component.Id, "service")}", "Arn"] }
            }
            [#if fixedIP]
                [#list 1..maxSize as index]
                    ,"${formatId("eip", tier.Id, component.Id, index, "ip")}": {
                        "Value" : { "Ref" : "${formatId("eip", tier.Id, component.Id, index)}" }
                    }
                    ,"${formatId("eip", tier.Id, component.Id, index, "id")}": {
                        "Value" : { "Fn::GetAtt" : ["${formatId("eip", tier.Id, component.Id, index)}", "AllocationId"] }
                    }
                [/#list]
            [/#if]
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]