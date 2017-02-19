[#-- EC2 --]
[#if component.EC2??]
    [@securityGroup /]
    [#assign ec2 = component.EC2]
    [#assign fixedIP = ec2.FixedIP?? && ec2.FixedIP]
    [#if resourceCount > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
            [#list ec2.Ports as port]
                "securityGroupIngressX${tier.Id}X${component.Id}X${ports[port].Port?c}" : {
                    "Type" : "AWS::EC2::SecurityGroupIngress",
                    "Properties" : {
                        "GroupId": {"Ref" : "securityGroupX${tier.Id}X${component.Id}"},
                        "IpProtocol": "${ports[port].IPProtocol}",
                        "FromPort": "${ports[port].Port?c}",
                        "ToPort": "${ports[port].Port?c}",
                        "CidrIp": "0.0.0.0/0"
                    }
                },
            [/#list]
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
                    "Policies": [
                        {
                            "PolicyName": "${tier.Id}-${component.Id}-basic",
                            "PolicyDocument" : {
                                "Version": "2012-10-17",
                                "Statement": [
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
                    "Roles" : [
                        { "Ref" : "roleX${tier.Id}X${component.Id}" }
                    ]
                }
            }

            [#list zones as zone]
                [#if multiAZ || (zones[0].Id = zone.Id)]
                    ,"ec2InstanceX${tier.Id}X${component.Id}X${zone.Id}": {
                        "Type": "AWS::EC2::Instance",
                        "Metadata": {
                            "AWS::CloudFormation::Init": {
                                "configSets" : {
                                    "ec2" : ["dirs", "bootstrap", "puppet"]
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
                                                        "echo \"cot:zone=${zone.Id}\"\n",
                                                        "echo \"cot:name=${productName}-${segmentName}-${tier.Name}-${component.Name}-${zone.Name}\"\n",
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
                                        [#if ec2.LoadBalanced]
                                            ,"03RegisterWithLB" : {
                                                "command" : "/opt/codeontap/bootstrap/register.sh",
                                                "env" : {
                                                    "LOAD_BALANCER" : { "Ref" : "elbXelbX${component.Id}" }
                                                },
                                                "ignoreErrors" : "false"
                                            }
                                        [/#if]
                                    }
                                },
                                "puppet": {
                                    "commands": {
                                        "01SetupPuppet" : {
                                            "command" : "/opt/codeontap/bootstrap/puppet.sh",
                                            "ignoreErrors" : "false"
                                        }
                                    }
                                }
                            }
                        },
                        [#assign processorProfile = getProcessor(tier, component, "EC2")]
                        [#assign storageProfile = getStorage(tier, component, "EC2")]
                        "Properties": {
                            [@createBlockDevices storageProfile=storageProfile /]
                            "DisableApiTermination" : false,
                            "EbsOptimized" : false,
                            "IamInstanceProfile" : { "Ref" : "instanceProfileX${tier.Id}X${component.Id}" },
                            "ImageId": "${regionObject.AMIs.Centos.EC2}",
                            "InstanceInitiatedShutdownBehavior" : "stop",
                            "InstanceType": "${processorProfile.Processor}",
                            "KeyName": "${productName + sshPerSegment?string("-" + segmentName,"")}",
                            "Monitoring" : false,
                            "NetworkInterfaces" : [
                                {
                                    "DeviceIndex" : "0",
                                    "NetworkInterfaceId" : { "Ref" : "eniX${tier.Id}X${component.Id}X${zone.Id}Xeth0" }
                                }
                            ],
                            "Tags" : [
                                { "Key" : "cot:request", "Value" : "${requestReference}" },
                                { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                                { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                                { "Key" : "cot:account", "Value" : "${accountId}" },
                                { "Key" : "cot:product", "Value" : "${productId}" },
                                { "Key" : "cot:segment", "Value" : "${segmentId}" },
                                { "Key" : "cot:environment", "Value" : "${environmentId}" },
                                { "Key" : "cot:category", "Value" : "${categoryId}" },
                                { "Key" : "cot:tier", "Value" : "${tier.Id}" },
                                { "Key" : "cot:component", "Value" : "${component.Id}" },
                                { "Key" : "cot:zone", "Value" : "${zone.Id}" },
                                { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}-${zone.Name}" }
                            ],
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
                                            "         --resource ec2InstanceX${tier.Id}X${component.Id}X${zone.Id}",
                                            "         --region ${regionId} --configsets ec2\n"
                                        ]
                                    ]
                                }
                            }
                        },
                        "DependsOn" : [
                            "eniX${tier.Id}X${component.Id}X${zone.Id}Xeth0"
                            [#if ec2.LoadBalanced]
                                ,"elbXelbX${component.Id}"
                            [/#if]
                            [#if fixedIP]
                                ,"eipAssocX${tier.Id}X${component.Id}X${zone.Id}Xeth0"
                            [/#if]
                        ]
                    },
                    "eniX${tier.Id}X${component.Id}X${zone.Id}Xeth0": {
                        "Type" : "AWS::EC2::NetworkInterface",
                        "Properties" : {
                            "Description" : "eth0",
                            "SubnetId" : "${getKey("subnetX"+tier.Id+"X"+zone.Id)}",
                            "SourceDestCheck" : true,
                            "GroupSet" : [
                                {"Ref" : "securityGroupX${tier.Id}X${component.Id}"}
                                [#if securityGroupNAT != "none"]
                                    , "${securityGroupNAT}"
                                [/#if]
                            ],
                            "Tags" : [
                                { "Key" : "cot:request", "Value" : "${requestReference}" },
                                { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                                { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                                { "Key" : "cot:account", "Value" : "${accountId}" },
                                { "Key" : "cot:product", "Value" : "${productId}" },
                                { "Key" : "cot:segment", "Value" : "${segmentId}" },
                                { "Key" : "cot:environment", "Value" : "${environmentId}" },
                                { "Key" : "cot:category", "Value" : "${categoryId}" },
                                { "Key" : "cot:tier", "Value" : "${tier.Id}" },
                                { "Key" : "cot:component", "Value" : "${component.Id}" },
                                { "Key" : "cot:zone", "Value" : "${zone.Id}" },
                                { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}-${zone.Name}-eth0" }
                            ]
                        }
                    }
                    [#if fixedIP]
                        [#if getKey("eipX${tier.Id}X${component.Id}X${zone.Id}Xip")??]
                            ,"eipX${tier.Id}X${component.Id}X${zone.Id}": {
                        [#else]
                            ,"eipX${tier.Id}X${component.Id}X${zone.Id}Xeth0": {
                        [/#if]
                            "DependsOn" : "eniX${tier.Id}X${component.Id}X${zone.Id}Xeth0",
                            "Type" : "AWS::EC2::EIP",
                            "Properties" : {
                                "Domain" : "vpc"
                            }
                        }
                        ,"eipAssocX${tier.Id}X${component.Id}X${zone.Id}Xeth0": {
                            [#if getKey("eipX${tier.Id}X${component.Id}X${zone.Id}Xip")??]
                                "DependsOn" : "eipX${tier.Id}X${component.Id}X${zone.Id}",
                            [#else]
                                "DependsOn" : "eipX${tier.Id}X${component.Id}X${zone.Id}Xeth0",
                            [/#if]
                            "Type" : "AWS::EC2::EIPAssociation",
                            "Properties" : {
                                [#if getKey("eipX${tier.Id}X${component.Id}X${zone.Id}Xip")??]
                                    "AllocationId" : { "Fn::GetAtt" : ["eipX${tier.Id}X${component.Id}X${zone.Id}", "AllocationId"] },
                                [#else]
                                    "AllocationId" : { "Fn::GetAtt" : ["eipX${tier.Id}X${component.Id}X${zone.Id}Xeth0", "AllocationId"] },
                                [/#if]
                                "NetworkInterfaceId" : { "Ref" : "eniX${tier.Id}X${component.Id}X${zone.Id}Xeth0" }
                            }
                        }
                    [/#if]
                [/#if]
            [/#list]
            [#break]

        [#case "outputs"]
            "roleX${tier.Id}X${component.Id}" : {
                "Value" : { "Ref" : "roleX${tier.Id}X${component.Id}" }
            },
            "roleX${tier.Id}X${component.Id}Xarn" : {
                "Value" : { "Fn::GetAtt" : ["roleX${tier.Id}X${component.Id}", "Arn"] }
            }
            [#if fixedIP]
                [#list zones as zone]
                    [#if multiAZ || (zones[0].Id = zone.Id)]
                        [#if getKey("eipX${tier.Id}X${component.Id}X${zone.Id}Xip")??]
                            ,"eipX${tier.Id}X${component.Id}X${zone.Id}Xip": {
                                "Value" : { "Ref" : "eipX${tier.Id}X${component.Id}X${zone.Id}" }
                            }
                            ,"eipX${tier.Id}X${component.Id}X${zone.Id}Xid": {
                                "Value" : { "Fn::GetAtt" : ["eipX${tier.Id}X${component.Id}X${zone.Id}", "AllocationId"] }
                            }
                        [#else]
                            ,"eipX${tier.Id}X${component.Id}X${zone.Id}Xeth0Xip": {
                                "Value" : { "Ref" : "eipX${tier.Id}X${component.Id}X${zone.Id}Xeth0" }
                            }
                            ,"eipX${tier.Id}X${component.Id}X${zone.Id}Xeth0Xid": {
                                "Value" : { "Fn::GetAtt" : ["eipX${tier.Id}X${component.Id}X${zone.Id}Xeth0", "AllocationId"] }
                            }
                        [/#if]
                    [/#if]
                [/#list]
            [/#if]
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]