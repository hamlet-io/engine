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
        [#assign dockerHost = solution.DockerHost]

        [#assign ec2SecurityGroupId     = resources["sg"].Id]
        [#assign ec2SecurityGroupName   = resources["sg"].Name]
        [#assign ec2RoleId              = resources["ec2Role"].Id]
        [#assign ec2InstanceProfileId   = resources["instanceProfile"].Id]

        [#assign targetGroupRegistrations = {}]
        [#assign targetGroupPermission = false ]

        [#assign configSetName = componentType ]
        [#assign configSets +=  
                getInitConfigDirectories() + 
                getInitConfigBootstrap(component.Role!"") +
                getInitConfigPuppet() ]

        [#assign efsMountPoints = {}]

        [#assign componentDependencies = []]
        [#assign ingressRules = []]

        [#list solution.Ports?values as port ]
            [#if port.LB.Configured]
                [#assign links += getLBLink(occurrence, port)]
            [#else]
                [#assign portCIDRs = getGroupCIDRs(port.IPAddressGroups) ]
                [#if portCIDRs?has_content]
                    [#assign ingressRules +=
                        [{
                            "Port" : port.Name,
                            "CIDR" : portCIDRs
                        }]]
                [/#if]
            [/#if]
        [/#list]

        [#list links?values as link]
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
                [#case LB_PORT_COMPONENT_TYPE]
                    [#assign targetGroupPermission = true]

                    [#switch linkTargetAttributes["ENGINE"]]

                        [#case "application"]
                        [#case "network"]
                            [#if link.TargetGroup?has_content ]
                                [#assign targetId = (linkTargetResources["targetgroups"][link.TargetGroup].Id) ]
                                [#if targetId?has_content]

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
                                        [#assign configSets +=
                                            getInitConfigLBTargetRegistration(targetId)]
                                    [/#if]
                                [/#if]
                            [/#if]
                            [#break]

                        [#case "classic" ]
                            [#assign lbId =  linkTargetAttributes["LB"] ]
                            [#assign configSets += 
                                getInitConfigLBClassicRegistration(lbId)]
                            [#break]
                        [/#switch]
                    [#break]
                [#case EFS_MOUNT_COMPONENT_TYPE]
                    [#assign configSets += 
                        getInitConfigEFSMount(
                            linkTargetCore.Id, 
                            linkTargetAttributes.EFS, 
                            linkTargetAttributes.DIRECTORY, 
                            link.Id
                        )]
                    [#break]
            [/#switch]
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
                                lbRegisterTargetPermission(),
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
                        metadata=getInitConfig(configSetName, configSets )
                        properties=
                            getBlockDevices(storageProfile) +
                            {
                                "DisableApiTermination" : false,
                                "EbsOptimized" : false,
                                "IamInstanceProfile" : { "Ref" : ec2InstanceProfileId },
                                "InstanceInitiatedShutdownBehavior" : "stop",
                                "InstanceType": processorProfile.Processor,
                                "KeyName": getExistingReference(formatEC2KeyPairId(), NAME_ATTRIBUTE_TYPE),
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
                                                "         --region ", regionId, " --configsets ",  configSetName, "\n"
                                            ]
                                        ]
                                    }
                                }
                            } +
                            dockerHost?then(
                                { "ImageId" : regionObject.AMIs.Centos.ECS},
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