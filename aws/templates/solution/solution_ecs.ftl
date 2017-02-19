[#-- ECS --]
[#if component.ECS??]
    [#assign ecs = component.ECS]
    [#assign processorProfile = getProcessor(tier, component, "ECS")]
    [#assign maxSize = processorProfile.MaxPerZone]
    [#if multiAZ]
        [#assign maxSize = maxSize * zones?size]
    [/#if]
    [#assign storageProfile = getStorage(tier, component, "ECS")]
    [#assign fixedIP = ecs.FixedIP?? && ecs.FixedIP]
    [#if count > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
            "ecsX${tier.Id}X${component.Id}" : {
                "Type" : "AWS::ECS::Cluster"
            },

            "roleX${tier.Id}X${component.Id}": {
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
                            "PolicyName": "${tier.Id}-${component.Id}-docker",
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
                                            "arn:aws:s3:::${operationsBucket}/DOCKERLogs/*"
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

            "instanceProfileX${tier.Id}X${component.Id}" : {
                "Type" : "AWS::IAM::InstanceProfile",
                "Properties" : {
                    "Path" : "/",
                    "Roles" : [ { "Ref" : "roleX${tier.Id}X${component.Id}" } ]
                }
            },

            "roleX${tier.Id}X${component.Id}Xservice": {
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
                    "eipX${tier.Id}X${component.Id}X${index}": {
                        "Type" : "AWS::EC2::EIP",
                        "Properties" : {
                            "Domain" : "vpc"
                        }
                    },
                [/#list]
            [/#if]

            "asgX${tier.Id}X${component.Id}": {
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
                                                            { "Fn::GetAtt" : ["eipX${tier.Id}X${component.Id}X${index}", "AllocationId"] }
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
                                        "ECS_CLUSTER" : { "Ref" : "ecsX${tier.Id}X${component.Id}" },
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
                    "LaunchConfigurationName": {"Ref": "launchConfigX${tier.Id}X${component.Id}"},
                    [#if multiAZ]
                        "MinSize": "${processorProfile.MinPerZone * zones?size}",
                        "MaxSize": "${maxSize}",
                        "DesiredCapacity": "${processorProfile.DesiredPerZone * zones?size}",
                        "VPCZoneIdentifier": [
                            [#list zones as zone]
                                "${getKey("subnetX"+tier.Id+"X"+zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
                            [/#list]
                        ],
                    [#else]
                        "MinSize": "${processorProfile.MinPerZone}",
                        "MaxSize": "${maxSize}",
                        "DesiredCapacity": "${processorProfile.DesiredPerZone}",
                        "VPCZoneIdentifier" : ["${getKey("subnetX"+tier.Id+"X"+zones[0].Id)}"],
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
                        { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}", "PropagateAtLaunch" : "True" }
                    ]
                }
            },

            "launchConfigX${tier.Id}X${component.Id}": {
                "Type": "AWS::AutoScaling::LaunchConfiguration",
                "Properties": {
                    "KeyName": "${productName + sshPerSegment?string("-" + segmentName,"")}",
                    "ImageId": "${regionObject.AMIs.Centos.ECS}",
                    "InstanceType": "${processorProfile.Processor}",
                    [@createBlockDevices storageProfile=storageProfile /]
                    "SecurityGroups" : [ {"Ref" : "securityGroupX${tier.Id}X${component.Id}"} [#if securityGroupNAT != "none"], "${securityGroupNAT}"[/#if] ],
                    "IamInstanceProfile" : { "Ref" : "instanceProfileX${tier.Id}X${component.Id}" },
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
                                    "         --resource asgX${tier.Id}X${component.Id}",
                                    "         --region ${regionId} --configsets ${configSet}\n"
                                ]
                            ]
                        }
                    }
                }
            }
            [#break]

        [#case "outputs"]
            "ecsX${tier.Id}X${component.Id}" : {
                "Value" : { "Ref" : "ecsX${tier.Id}X${component.Id}" }
            },
            "roleX${tier.Id}X${component.Id}" : {
                "Value" : { "Ref" : "roleX${tier.Id}X${component.Id}" }
            },
            "roleX${tier.Id}X${component.Id}Xarn" : {
                "Value" : { "Fn::GetAtt" : ["roleX${tier.Id}X${component.Id}", "Arn"] }
            },
            "roleX${tier.Id}X${component.Id}Xservice" : {
                "Value" : { "Ref" : "roleX${tier.Id}X${component.Id}Xservice" }
            },
            "roleX${tier.Id}X${component.Id}XserviceXarn" : {
                "Value" : { "Fn::GetAtt" : ["roleX${tier.Id}X${component.Id}Xservice", "Arn"] }
            }
            [#if fixedIP]
                [#list 1..maxSize as index]
                    ,"eipX${tier.Id}X${component.Id}X${index}Xip": {
                        "Value" : { "Ref" : "eipX${tier.Id}X${component.Id}X${index}" }
                    }
                    ,"eipX${tier.Id}X${component.Id}X${index}Xid": {
                        "Value" : { "Fn::GetAtt" : ["eipX${tier.Id}X${component.Id}X${index}", "AllocationId"] }
                    }
                [/#list]
            [/#if]
            [#break]

    [/#switch]
    [#assign count += 1]
[/#if]