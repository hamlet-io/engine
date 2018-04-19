[#-- EC2 --]

[#if componentType == EC2_COMPONENT_TYPE]
    [#list requiredOccurrences(
        getOccurrences(tier, component),
        deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core]
        [#assign solution = occurrence.Configuration.Solution]
        [#assign resources = occurrence.State.Resources]
        [#assign zoneResources = occurrence.State.Resources.Zones]
        [#assign links = solution.Links ]

        [#assign fixedIP = solution.FixedIP]
        [#assign loadBalanced = solution.LoadBalanced]
        [#assign dockerHost = solution.DockerHost]

        [#assign ec2FullName            = resources["ec2Instance"].Name ]
        [#assign ec2SecurityGroupId     = resources["sg"].Id]
        [#assign ec2SecurityGroupName   = resources["sg"].Name]
        [#assign ec2RoleId              = resources["ec2Role"].Id]
        [#assign ec2InstanceProfileId   = resources["instanceProfile"].Id]
        [#assign ec2ELBId               = resources["ec2ELB"].Id]

        [#assign targetGroupRegistrations = {}]
        [#assign targetGroupPermission = false ]

        [#assign scriptsFile = ""]

        [#if buildDeploymentUnit?has_content && buildCommit?has_content ]
            [#assign scriptsFile = formatRelativePath(
                                        getRegistryEndPoint("scripts"),
                                        getRegistryPrefix("scripts") + productName,
                                        buildDeploymentUnit,
                                        buildCommit,
                                        "scripts.zip")]
        [/#if]


        [#assign componentDependencies = []]
        [#assign ingressRules = []]

        [#if solution.Ports?is_hash?has_content ]
            [#list solution.Ports as id,port ]
                [#assign links += getLBLink(occurrence port)] 
            [/#list]
        [#else]
            [#list solution.Ports as port]
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
        [/#if]

        [#list links?values as link]
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
                [#case ALB_PORT_COMPONENT_TYPE]
                    [#if link.TargetGroup?has_content ]
                        [#assign targetId = (linkTargetResources["targetgroups"][link.TargetGroup].Id) ]
                        [#if targetId?has_content]

                            [#assign targetGroupPermission = true]

                            [#if deploymentSubsetRequired("ec2", true)]
                                [#if isPartOfCurrentDeploymentUnit(targetId)]

                                    [@createTargetGroup
                                        mode=listMode
                                        id=targetId
                                        name=formatName(linkTargetCore.FullName,link.TargetGroup)
                                        tier=link.Tier
                                        component=link.Component
                                        destination=ports[link.Port]
                                    /]
                                    [#assign listenerRuleId = formatALBListenerRuleId(occurrence, link.TargetGroup) ]
                                    [@createListenerRule
                                        mode=listMode
                                        id=listenerRuleId
                                        listenerId=linkTargetResources["listener"].Id
                                        actions=getListenerRuleForwardAction(targetId)
                                        conditions=getListenerRulePathCondition(link.TargetPath)
                                        priority=link.Priority!100
                                        dependencies=targetId
                                    /]
                                    
                                    [#assign componentDependencies += [targetId]]
                                    
                                [/#if]
                                [#assign targetGroupRegistrations += 
                                        {
                                            "03RegisterWithTG" + targetId  : {
                                                "command" : "/opt/codeontap/bootstrap/register_targetgroup.sh",
                                                "env" : {
                                                    "TARGET_GROUP_ARN" : getReference(targetId)
                                                },
                                                "ignoreErrors" : "false"
                                            }
                                        }
                                    ]
                            [/#if]
                        [/#if]
                    [/#if]
                    [#break]
            [/#switch]
        [/#if]
    [/#list]
        
    [#if deploymentSubsetRequired("iam", true) &&
            isPartOfCurrentDeploymentUnit(ec2RoleId)]

        [@createRole
            mode=listMode
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
                ] + targetGroupPermission?then(
                    [   
                        getPolicyDocument(
                            albRegisterTargetPermission(),
                            "loadbalancing")
                    ],
                    [])
        /]
    [/#if]

    [#if deploymentSubsetRequired("ec2", true)]

        [@createSecurityGroup
            mode=listMode
            id=ec2SecurityGroupId
            name=ec2SecurityGroupName
            tier=tier
            component=component
            ingressRules=ingressRules /]

        [@cfResource
            mode=listMode
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
                [#assign zoneEc2InstanceId          = zoneResources[zone.Id]["ec2Instance"].Id ]
                [#assign zoneEc2InstanceName        = zoneResources[zone.Id]["ec2Instance"].Name ]
                [#assign zoneEc2ENIId               = zoneResources[zone.Id]["ec2ENI"].Id ]
                [#assign zoneEc2EIPId               = zoneResources[zone.Id]["ec2EIP"].Id]
                [#assign zoneEc2EIPAssociationId    = zoneResources[zone.Id]["ec2EIPAssociation"].Id]

                [#assign processorProfile = getProcessor(tier, component, "EC2")]
                [#assign storageProfile = getStorage(tier, component, "EC2")]
                [#assign updateCommand = "yum clean all && yum -y update"]
                [#assign dailyUpdateCron = 'echo \"59 13 * * * ${updateCommand} >> /var/log/update.log 2>&1\" >crontab.txt && crontab crontab.txt']
                [#if environmentId == "prod"]
                    [#-- for production update only security packages --]
                   [#assign updateCommand += " --security"]
                    [#assign dailyUpdateCron = 'echo \"29 13 * * 6 ${updateCommand} >> /var/log/update.log 2>&1\" >crontab.txt && crontab crontab.txt']
                [/#if]

                [@cfResource
                    mode=listMode
                    id=zoneEc2InstanceId
                    type="AWS::EC2::Instance"
                    metadata=
                        {
                            "AWS::CloudFormation::Init": {
                                "configSets" : {
                                    "ec2" : ["dirs", "bootstrap", "puppet"] + 
                                        scriptsFile?has_content?then(
                                            ["scripts"],
                                            []
                                        )
                                },
                                "dirs": {
                                    "commands": {
                                        "01Directories" : {
                                            "command" : "mkdir --parents --mode=0755 /etc/codeontap &&" +
                                                        "mkdir --parents --mode=0755 /opt/codeontap/bootstrap &&" +
                                                        "mkdir --parents --mode=0755 /var/log/codeontap &&" +
                                                        "mkdir --parents --mode=0755 /opt/codeontap/scripts",
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
                                                        "echo \\\"cot:name="          + zoneEc2InstanceName    + "\\\"\\n",
                                                        "echo \\\"cot:role="          + component.Role!""      + "\\\"\\n",
                                                        "echo \\\"cot:credentials="   + credentialsBucket      + "\\\"\\n",
                                                        "echo \\\"cot:code="          + codeBucket             + "\\\"\\n",
                                                        "echo \\\"cot:logs="          + operationsBucket       + "\\\"\\n",
                                                        "echo \\\"cot:backups="       + dataBucket             + "\\\"\\n"
                                                    ] + 
                                                    scriptsFile?has_content?then(
                                                        [
                                                            "echo \\\"cot:scripts="       + scriptsFile             + "\\\"\\n"
                                                        ],
                                                        []
                                                    )
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
                                    attributeIfTrue(
                                        "03RegisterWithLB",
                                        loadBalanced,
                                        {
                                            "command" : "/opt/codeontap/bootstrap/register.sh",
                                            "env" : {
                                                "LOAD_BALANCER" : getReference(ec2ELBId)
                                            },
                                            "ignoreErrors" : "false"
                                        }) +
                                    targetGroupRegistrations
                                },
                                "puppet": {
                                    "commands": {
                                        "01SetupPuppet" : {
                                            "command" : "/opt/codeontap/bootstrap/puppet.sh",
                                            "ignoreErrors" : "false"
                                        }
                                    }
                                } + 
                                scriptsFile?has_content?then(
                                {
                                "scripts" : {
                                    "files" :{
                                        "/opt/codeontap/fetch_scripts.sh" : {
                                            "content" : {
                                                "Fn::Join" : [
                                                    "",
                                                    [
                                                        "#!/bin/bash -ex\\n",
                                                        "exec > >(tee /var/log/codeontap/fetch.log|logger -t codeontap-scripts-fetch -s 2>/dev/console) 2>&1\\n",
                                                        "REGION=$(/etc/codeontap/facts.sh | grep cot:accountRegion | cut -d '=' -f 2)\\n",
                                                        "SCRIPTS=$(/etc/codeontap/facts.sh | grep cot:scripts | cut -d '=' -f 2)\\n",
                                                        "if [ -z " + r"${SCRIPTS}" +" ]; then\\n",
                                                        "aws --region " + r"${REGION}" + " s3 cp --quiet s3://" + r"${SCRIPTS}" + " /opt/codeontap/scripts\\n", 
                                                        "[ -f /opt/codeontap/scripts/scripts.zip ] && unzip /opt/codeontap/scripts/scripts.zip\\n",
                                                        "chmod -R 0500 /opt/codeontap/scripts/\\n"
                                                        "fi\\n"
                                                    ]
                                                ]
                                            },
                                            "mode" : "000755"
                                        },
                                        "/opt/codeontap/run_scripts.sh" : {
                                            "content" : {
                                                "Fn::Join" : [
                                                    "",
                                                    [
                                                        "#!/bin/bash -ex\\n",
                                                        "exec > >(tee /var/log/codeontap/fetch.log|logger -t codeontap-scripts-init -s 2>/dev/console) 2>&1\\n",
                                                        "[ -f /opt/codeontap/scripts/init.sh ] &&  /opt/codeontap/scripts/init.sh\\n" 
                                                    ]
                                                ]
                                            },
                                            "mode" : "000755"
                                        }
                                    },
                                    "commands" : {
                                        "01FetchScripts" : {
                                            "command" : "/opt/codeontap/fetch_scripts.sh",
                                            "ignoreErrors" : "false"
                                        },
                                        "02RunInitScript" : {
                                            "command" : "/opt/codeontap/run_scripts.sh",
                                            "ignoreErrors" : "false"
                                        }
                                    }

                                }
                                },
                                {})
                            }
                        }
                    properties=
                        getBlockDevices(storageProfile) +
                        {
                            "DisableApiTermination" : false,
                            "EbsOptimized" : false,
                            "IamInstanceProfile" : { "Ref" : ec2InstanceProfileId },
                            "InstanceInitiatedShutdownBehavior" : "stop",
                            "InstanceType": processorProfile.Processor,
                            "KeyName": productName + sshPerSegment?then("-" + segmentName,""),
                            "Monitoring" : false,
                            "NetworkInterfaces" : [
                                {
                                    "DeviceIndex" : "0",
                                    "NetworkInterfaceId" : getReference(zoneEc2ENIId)
                                }
                            ],
                            "UserData" : {
                                "Fn::Base64" : {
                                    "Fn::Join" : [
                                        "",
                                        [
                                            "#!/bin/bash -ex\n",
                                            "exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1\n",
                                            updateCommand, "\n",
                                            dailyUpdateCron, "\n",
                                            "yum install -y aws-cfn-bootstrap\n",
                                            "# Remainder of configuration via metadata\n",
                                            "/opt/aws/bin/cfn-init -v",
                                            "         --stack ", { "Ref" : "AWS::StackName" },
                                            "         --resource ", zoneEc2InstanceId,
                                            "         --region ", regionId, " --configsets ec2\\n"
                                        ]
                                    ]
                                }
                            }
                        } +
                        dockerHost?then(
                            { "ImageId" : regionObject.AMIs.Centos.ECS },
                            { "ImageId" : regionObject.AMIs.Centos.EC2} 
                        )
                    tags=
                        getCfTemplateCoreTags(
                            formatComponentFullName(tier, component, zone),
                            tier,
                            component,
                            zone)
                    outputs={}
                    dependencies=[zoneEc2ENIId] +
                        componentDependencies + 
                        loadBalanced?then(
                            [ec2ELBId],
                            []
                        ) +
                        fixedIP?then(
                            [zoneEc2EIPAssociationId],
                            [])
                /]

                [@cfResource
                    mode=listMode
                    id=zoneEc2ENIId
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
                        mode=listMode
                        id=zoneEc2EIPId
                        dependencies=[zoneEc2ENIId]
                    /]

                    [@cfResource
                        mode=listMode
                        id=zoneEc2EIPAssociationId
                        type="AWS::EC2::EIPAssociation"
                        properties=
                            {
                                "AllocationId" : getReference(zoneEc2EIPId, ALLOCATION_ATTRIBUTE_TYPE),
                                "NetworkInterfaceId" : getReference(zoneEc2ENIId)
                            }
                        dependencies=[zoneEc2EIPId]
                        outputs={}
                    /]
                [/#if]
            [/#if]
        [/#list]
        [/#if]
    [/#list]
[/#if]