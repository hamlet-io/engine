[#-- EC2 --]
[#if componentType == "ec2"]
    [#assign ec2 = component.EC2]
    [#assign fixedIP = ec2.FixedIP?? && ec2.FixedIP]

    [#assign ec2FullName = formatName(tenantId, componentFullName) ]
    [#assign ec2SecurityGroupId = formatEC2SecurityGroupId(tier, component)]
    [#assign ec2RoleId = formatEC2RoleId(tier, component)]
    [#assign ec2InstanceProfileId = formatEC2InstanceProfileId(tier, component)]
    [#assign ec2ELBId = formatELBId("elb", component)]
    
    [#assign ingressRules = []]
    [#list ec2.Ports as port]
        [#assign nextPort = port?is_hash?then(port.Port, port)]
        [#assign portCIDRs = getUsageCIDRs(
                            nextPort,
                            port?is_hash?then(port.IPAddressGroups![], []))]
        [#if portCIDRs?has_content]
            [#assign ingressRules +=
                [{
                    "Port" : nextPort,
                    "CIDR" : portCIDRs
                }]]
        [/#if]
    [/#list]    
    
    [@createComponentSecurityGroup solutionListMode tier component "" "" ingressRules /]
    
    [#switch solutionListMode]
        [#case "definition"]

            [@roleHeader
                ec2RoleId,
                ["ec2.amazonaws.com" ]
            /]
                [@policyHeader
                    formatComponentShortName(
                        tier,
                        component,
                        "basic") /]
                    [@s3ListStatement codeBucket /]
                    [@s3ReadStatement codeBucket /]
                    [@s3ListStatement operationsBucket /]
                    [@s3WriteStatement operationsBucket "DOCKERLogs" /]
                    [@s3WriteStatement operationsBucket "Backups" /]
                [@policyFooter /]
            [@roleFooter /]

            [@checkIfResourcesCreated /]
            "${ec2InstanceProfileId}" : {
                "Type" : "AWS::IAM::InstanceProfile",
                "Properties" : {
                    "Path" : "/",
                    "Roles" : [
                        { "Ref" : "${ec2RoleId}" }
                    ]
                }
            }
            [@resourcesCreated /]

            [#list zones as zone]
                [#if multiAZ || (zones[0].Id = zone.Id)]
                    [#assign ec2InstanceId =
                                formatEC2InstanceId(
                                    tier,
                                    component,
                                    zone)]
                    [#assign ec2ENIId = 
                                formatEC2ENIId(
                                    tier,
                                    component,
                                    zone,
                                    "eth0")]
                    [#assign ec2EIPId = formatComponentEIPId(
                                            tier,
                                            component,
                                            zone)]
                    [#-- Support backwards compatability with existing installs --] 
                    [#if !(getKey(ec2EIPId)?has_content)]
                        [#assign ec2EIPId = formatComponentEIPId(
                                                tier,
                                                component,
                                                zone
                                                "eth0")]
                    [/#if]

                    [#assign ec2EIPAssociationId = 
                                formatComponentEIPAssociationId(
                                    tier,
                                    component,
                                    zone,
                                    "eth0")]

                    [@checkIfResourcesCreated /]
                    "${ec2InstanceId}": {
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
                                                        "echo \"cot:tier=${tierId}\"\n",
                                                        "echo \"cot:component=${componentId}\"\n",
                                                        "echo \"cot:zone=${zone.Id}\"\n",
                                                        "echo \"cot:name=${formatName(ec2FullName, zone)}\"\n",
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
                                                    "LOAD_BALANCER" : { "Ref" : "${ec2ELBId}" }
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
                            "IamInstanceProfile" : { "Ref" : "${ec2InstanceProfileId}" },
                            "ImageId": "${regionObject.AMIs.Centos.EC2}",
                            "InstanceInitiatedShutdownBehavior" : "stop",
                            "InstanceType": "${processorProfile.Processor}",
                            "KeyName": "${productName + sshPerSegment?string("-" + segmentName,"")}",
                            "Monitoring" : false,
                            "NetworkInterfaces" : [
                                {
                                    "DeviceIndex" : "0",
                                    "NetworkInterfaceId" : { "Ref" : "${ec2ENIId}" }
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
                                { "Key" : "cot:tier", "Value" : "${tierId}" },
                                { "Key" : "cot:component", "Value" : "${componentId}" },
                                { "Key" : "cot:zone", "Value" : "${zone.Id}" },
                                { "Key" : "Name", "Value" : "${formatComponentFullName(
                                                                tier,
                                                                component,
                                                                zone)}" }
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
                                            "         --resource ${ec2InstanceId}",
                                            "         --region ${regionId} --configsets ec2\n"
                                        ]
                                    ]
                                }
                            }
                        },
                        "DependsOn" : [
                            "${ec2ENIId}"
                            [#if ec2.LoadBalanced]
                                ,"${ec2ELBId}"
                            [/#if]
                            [#if fixedIP]
                                ,"${ec2EIPAssociationId}"
                            [/#if]
                        ]
                    },
                    "${ec2ENIId}" : {
                        "Type" : "AWS::EC2::NetworkInterface",
                        "Properties" : {
                            "Description" : "eth0",
                            "SubnetId" : "${getKey(formatSubnetId(tier, zone))}",
                            "SourceDestCheck" : true,
                            "GroupSet" : [
                                {"Ref" : "${ec2SecurityGroupId}"}
                                [#if sshFromProxySecurityGroup?has_content]
                                    , "${sshFromProxySecurityGroup}"
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
                                { "Key" : "cot:tier", "Value" : "${tierId}" },
                                { "Key" : "cot:component", "Value" : "${componentId}" },
                                { "Key" : "cot:zone", "Value" : "${zone.Id}" },
                                { "Key" : "Name", "Value" : "${formatComponentFullName(
                                                                tier,
                                                                component,
                                                                zone,
                                                                "eth0")}" }
                            ]
                        }
                    }
                    [#if fixedIP]
                        ,"${ec2EIPId}": {
                            "DependsOn" : "${ec2ENIId}",
                            "Type" : "AWS::EC2::EIP",
                            "Properties" : {
                                "Domain" : "vpc"
                            }
                        }
                        ,"${ec2EIPAssociationId}": {
                            "DependsOn" : "${ec2EIPId}",
                            "Type" : "AWS::EC2::EIPAssociation",
                            "Properties" : {
                                "AllocationId" : { "Fn::GetAtt" : ["${ec2EIPId}", "AllocationId"] },
                                "NetworkInterfaceId" : { "Ref" : "${ec2ENIId}" }
                            }
                        }
                    [/#if]
                [/#if]
            [/#list]
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output ec2RoleId /]
            [@outputArn ec2RoleId /]
            [#if fixedIP]
                [#list zones as zone]
                    [#if multiAZ || (zones[0].Id = zone.Id)]
                        [#assign ec2EIPId = formatComponentEIPId(
                                                tier,
                                                component,
                                                zone)]
                        [#-- Support backwards compatability with existing installs --] 
                        [#if !(getKey(ec2EIPId)?has_content)]
                            [#assign ec2EIPId = formatComponentEIPId(
                                                    tier,
                                                    component,
                                                    zone
                                                    "eth0")]
                        [/#if]

                        [@outputIPAddress ec2EIPId /]
                        [@outputAllocation ec2EIPId /]
                    [/#if]
                [/#list]
            [/#if]
            [#break]

    [/#switch]
[/#if]