[#-- EC2 --]
[#if component.EC2??]
    [@securityGroup solutionListMode tier component /]
    [#assign ec2 = component.EC2]
    [#assign fixedIP = ec2.FixedIP?? && ec2.FixedIP]
    [#if resourceCount > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
            [#list ec2.Ports as port]
                "${formatId("securityGroupIngress", tier.Id, component.Id, ports[port].Port?c)}" : {
                    "Type" : "AWS::EC2::SecurityGroupIngress",
                    "Properties" : {
                        "GroupId": {"Ref" : "${formatId("securityGroup", tier.Id, component.Id)}"},
                        "IpProtocol": "${ports[port].IPProtocol}",
                        "FromPort": "${ports[port].Port?c}",
                        "ToPort": "${ports[port].Port?c}",
                        "CidrIp": "0.0.0.0/0"
                    }
                },
            [/#list]
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
                    "Policies": [
                        {
                            "PolicyName": "${formatName(tier.Id, component.Id, "basic")}",
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
                    "Roles" : [
                        { "Ref" : "${formatId("role", tier.Id, component.Id)}" }
                    ]
                }
            }

            [#list zones as zone]
                [#if multiAZ || (zones[0].Id = zone.Id)]
                    ,"${formatId("ec2Instance", tier.Id, component.Id, zone.Id)}": {
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
                                                        "echo \"cot:name=${formatName(productName, segmentName, tier.Name, component.Name, zone.Name)}\"\n",
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
                                                    "LOAD_BALANCER" : { "Ref" : "${formatId("elb", "elb", component.Id)}" }
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
                            "IamInstanceProfile" : { "Ref" : "${formatId("instanceProfile", tier.Id, component.Id)}" },
                            "ImageId": "${regionObject.AMIs.Centos.EC2}",
                            "InstanceInitiatedShutdownBehavior" : "stop",
                            "InstanceType": "${processorProfile.Processor}",
                            "KeyName": "${productName + sshPerSegment?string("-" + segmentName,"")}",
                            "Monitoring" : false,
                            "NetworkInterfaces" : [
                                {
                                    "DeviceIndex" : "0",
                                    "NetworkInterfaceId" : { "Ref" : "${formatId("eni", tier.Id, component.Id, zone.Id, "eth0")}" }
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
                                { "Key" : "Name", "Value" : "${formatName(productName, segmentName, tier.Name, component.Name, zone.Name)}" }
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
                                            "         --resource ${formatId("ec2Instance", tier.Id, component.Id, zone.Id)}",
                                            "         --region ${regionId} --configsets ec2\n"
                                        ]
                                    ]
                                }
                            }
                        },
                        "DependsOn" : [
                            "${formatId("eni", tier.Id, component.Id, zone.Id, "eth0")}"
                            [#if ec2.LoadBalanced]
                                ,"${formatId("elb", "elb", component.Id)}"
                            [/#if]
                            [#if fixedIP]
                                ,"${formatId("eipAssoc", tier.Id, component.Id, zone.Id, "eth0")}"
                            [/#if]
                        ]
                    },
                    "${formatId("eni", tier.Id, component.Id, zone.Id, "eth0")}: {
                        "Type" : "AWS::EC2::NetworkInterface",
                        "Properties" : {
                            "Description" : "eth0",
                            "SubnetId" : "${getKey("subnet", tier.Id, zone.Id)}",
                            "SourceDestCheck" : true,
                            "GroupSet" : [
                                {"Ref" : "${formatId("securityGroup", tier.Id, component.Id)}"}
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
                                { "Key" : "Name", "Value" : "${formatName(productName, segmentName, tier.Name, component.Name, zone.Name, "eth0")}" }
                            ]
                        }
                    }
                    [#if fixedIP]
                        [#if getKey("eip", tier.Id, component.Id, zone.Id, "ip")??]
                            ,"${formatId("eip", tier.Id, component.Id, zone.Id)}": {
                        [#else]
                            ,"${formatId("eip", tier.Id, component.Id, zone.Id, "eth0")}": {
                        [/#if]
                            "DependsOn" : "${formatId("eni", tier.Id, component.Id, zone.Id, "eth0")}",
                            "Type" : "AWS::EC2::EIP",
                            "Properties" : {
                                "Domain" : "vpc"
                            }
                        }
                        ,"${formatId("eipAssoc", tier.Id, component.Id, zone.Id, "eth0")}": {
                            [#if getKey("eip", tier.Id, component.Id, zone.Id, "ip")??]
                                "DependsOn" : "${formatId("eip", tier.Id, component.Id, zone.Id)}",
                            [#else]
                                "DependsOn" : "${formatId("eip", tier.Id, component.Id, zone.Id, "eth0")}",
                            [/#if]
                            "Type" : "AWS::EC2::EIPAssociation",
                            "Properties" : {
                                [#if getKey("eip", tier.Id, component.Id, zone.Id, "ip")??]
                                    "AllocationId" : { "Fn::GetAtt" : ["${formatId("eip", tier.Id, component.Id, zone.Id)}", "AllocationId"] },
                                [#else]
                                    "AllocationId" : { "Fn::GetAtt" : ["${formatId("eip", tier.Id, component.Id, zone.Id, "eth0")}", "AllocationId"] },
                                [/#if]
                                "NetworkInterfaceId" : { "Ref" : "${formatId("eni", tier.Id, component.Id, zone.Id, "eth0")}" }
                            }
                        }
                    [/#if]
                [/#if]
            [/#list]
            [#break]

        [#case "outputs"]
            "${formatId("role", tier.Id, component.Id)}" : {
                "Value" : { "Ref" : "${formatId("role", tier.Id, component.Id)}" }
            },
            "${formatId("role", tier.Id, component.Id, "arn")}" : {
                "Value" : { "Fn::GetAtt" : ["${formatId("role", tier.Id, component.Id)}", "Arn"] }
            }
            [#if fixedIP]
                [#list zones as zone]
                    [#if multiAZ || (zones[0].Id = zone.Id)]
                        [#if getKey("eip", tier.Id, component.Id, zone.Id, "ip")??]
                            ,"${formatId("eip", tier.Id, component.Id, zone.Id, "ip")}": {
                                "Value" : { "Ref" : "${formatId("eip", tier.Id, component.Id, zone.Id)}" }
                            }
                            ,"${formatId("eip", tier.Id, component.Id, zone.Id, "id")}": {
                                "Value" : { "Fn::GetAtt" : ["${formatId("eip", tier.Id, component.Id, zone.Id)}", "AllocationId"] }
                            }
                        [#else]
                            ,"${formatId("eip", tier.Id, component.Id, zone.Id, "eth0", "ip")}": {
                                "Value" : { "Ref" : "${formatId("eip", tier.Id, component.Id, zone.Id, "eth0")}" }
                            }
                            ,"${formatId("eip", tier.Id, component.Id, zone.Id, "eth0", "id")}": {
                                "Value" : { "Fn::GetAtt" : ["${formatId("eip", tier.Id, component.Id, zone.Id, "eth0")}", "AllocationId"] }
                            }
                        [/#if]
                    [/#if]
                [/#list]
            [/#if]
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]