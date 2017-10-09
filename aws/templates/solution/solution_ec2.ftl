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

    [#if deploymentSubsetRequired("iam", true) &&
            isPartOfCurrentDeploymentUnit(ec2RoleId)]
        [@createRole
            mode=solutionListMode
            id=ec2RoleId
            trustedServices=["ec2.amazonaws.com" ]
            policies=
                [
                    getPolicyDocument(
                        s3ListPermission(codeBucket) +
                            s3ReadPermission(codeBucket) +
                            s3ListPermission(operationsBucket) +
                            s3WritePermission(operationsBucket, "DOCKERLogs") +
                            s3WritePermission(operationsBucket, "Backups"),
                        "basic")
                ]
        /]
    [/#if]

    [#if deploymentSubsetRequired("ec2", true)]
    
        [@createComponentSecurityGroup
            mode=solutionListMode
            tier=tier
            component=component
            ingressRules=ingressRules
         /]
        
        
        [@cfResource
            mode=solutionListMode
            id=ec2InstanceProfileId
            type="AWS::IAM::InstanceProfile"
            properties=
                {
                    "Path" : "/",
                    "Roles" : [getReference(ec2RoleId)]
                }
            outputs={}
        /]
    
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
                [#if !(getExistingReference(ec2EIPId)?has_content)]
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
    
                [#assign processorProfile = getProcessor(tier, component, "EC2")]
                [#assign storageProfile = getStorage(tier, component, "EC2")]
    
                [@cfResource
                    mode=solutionListMode
                    id=ec2InstanceId
                    type="AWS::EC2::Instance"
                    metadata=
                        {
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
                                                        "echo \\\"cot:zone="          + zone.Id                + "\\\"\\n",
                                                        "echo \\\"cot:name="          + formatName(ec2FullName, zone) + "\\\"\\n",
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
                                    attributeIfTrue(
                                        "03RegisterWithLB",
                                        ec2.LoadBalanced,
                                        {
                                            "command" : "/opt/codeontap/bootstrap/register.sh",
                                            "env" : {
                                                "LOAD_BALANCER" : getReference(ec2ELBId)
                                            },
                                            "ignoreErrors" : "false"
                                        })
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
                        }
                    properties=    
                        getBlockDevices(storageProfile) +
                        {
                            "DisableApiTermination" : false,
                            "EbsOptimized" : false,
                            "IamInstanceProfile" : { "Ref" : ec2InstanceProfileId },
                            "ImageId": regionObject.AMIs.Centos.EC2,
                            "InstanceInitiatedShutdownBehavior" : "stop",
                            "InstanceType": processorProfile.Processor,
                            "KeyName": productName + sshPerSegment?then("-" + segmentName,""),
                            "Monitoring" : false,
                            "NetworkInterfaces" : [
                                {
                                    "DeviceIndex" : "0",
                                    "NetworkInterfaceId" : getReference(ec2ENIId)
                                }
                            ],
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
                                            "         --resource ", ec2InstanceId,
                                            "         --region ", regionId, " --configsets ec2\\n"
                                        ]
                                    ]
                                }
                            }
                        }
                    tags=
                        getCfTemplateCoreTags(
                            formatComponentFullName(tier, component, zone),
                            tier,
                            component,
                            zone)
                    outputs={}
                    dependencies=
                        [ec2ENIId] +
                        ec2.LoadBalanced?then(
                            [ec2ELBId],
                            []
                        ) + 
                        fixedIP?then(
                            [ec2EIPAssociationId],
                            []
                        )
                /]
    
                [@cfResource
                    mode=solutionListMode
                    id=ec2ENIId
                    type="AWS::EC2::NetworkInterface"
                    properties=
                        {
                            "Description" : "eth0",
                            "SubnetId" : getReference(formatSubnetId(tier, zone)),
                            "SourceDestCheck" : true,
                            "GroupSet" :
                                [getReference(ec2SecurityGroupId)] +
                                sshFromProxySecurityGroup?has_content?then(
                                    [sshFromProxySecurityGroup],
                                    []
                                )
                        }
                    tags=
                        getCfTemplateCoreTags(
                            formatComponentFullName(tier, component, zone, "eth0"),
                            tier,
                            component,
                            zone)
                    outputs={}
                /]
                
                [#if fixedIP]
                    [@createEIP
                        mode=solutionListMode
                        id=ec2EIPId
                        dependencies=[ec2ENIId]
                    /]
                    
                    [@cfResource
                        mode=solutionListMode
                        id=ec2EIPAssociationId
                        type="AWS::EC2::EIPAssociation"
                        properties=
                            {
                                "AllocationId" : getReference(ec2EIPId, ALLOCATION_ATTRIBUTE_TYPE),
                                "NetworkInterfaceId" : getReference(ec2ENIId)
                            }
                        dependencies=[ec2EIPId]
                        outputs={}
                    /]
                [/#if]
            [/#if]
        [/#list]
    [/#if]
[/#if]