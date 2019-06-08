[#ftl]
[#macro aws_ec2_cf_solution occurrence ]
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
    [#assign ec2LogGroupId          = resources["lg"].Id]
    [#assign ec2LogGroupName        = resources["lg"].Name]

    [#assign processorProfile       = getProcessor(occurrence, "EC2")]
    [#assign storageProfile         = getStorage(occurrence, "EC2")]
    [#assign logFileProfile         = getLogFileProfile(occurrence, "EC2")]
    [#assign bootstrapProfile       = getBootstrapProfile(occurrence, "EC2")]

    [#assign occurrenceNetwork = getOccurrenceNetwork(occurrence) ]
    [#assign networkLink = occurrenceNetwork.Link!{} ]

    [#assign networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]

    [#if ! networkLinkTarget?has_content ]
        [@cfException listMode "Network could not be found" networkLink /]
        [#return]
    [/#if]

    [#assign networkConfiguration = networkLinkTarget.Configuration.Solution]
    [#assign networkResources = networkLinkTarget.State.Resources ]

    [#assign vpcId = networkResources["vpc"].Id ]

    [#assign routeTableLinkTarget = getLinkTarget(occurrence, networkLink + { "RouteTable" : occurrenceNetwork.RouteTable })]
    [#assign routeTableConfiguration = routeTableLinkTarget.Configuration.Solution ]
    [#assign publicRouteTable = routeTableConfiguration.Public ]

    [#assign targetGroupRegistrations = {}]
    [#assign targetGroupPermission = false ]

    [#assign environmentVariables = {}]

    [#assign configSetName = occurrence.Core.Type]
    [#assign configSets =
            getInitConfigDirectories() +
            getInitConfigBootstrap(occurrence) +
            getInitConfigPuppet() ]

    [#assign efsMountPoints = {}]

    [#assign componentDependencies = []]
    [#assign ingressRules = []]

    [#list solution.Ports?values as port ]
        [#if port.LB.Configured]
            [#assign lbLink = getLBLink(occurrence, port)]
            [#if isDuplicateLink(links, lbLink) ]
                [@cfException
                    mode=listMode
                    description="Duplicate Link Name"
                    context=links
                    detail=lbLink /]
                [#continue]
            [/#if]
            [#assign links += lbLink]
        [#else]
            [#assign portCIDRs = getGroupCIDRs(port.IPAddressGroups, true, occurrence) ]
            [#if portCIDRs?has_content]
                [#assign ingressRules +=
                    [{
                        "Port" : port.Name,
                        "CIDR" : portCIDRs
                    }]]
            [/#if]
        [/#if]
    [/#list]

    [#assign fragment = getOccurrenceFragmentBase(occurrence) ]

    [#assign contextLinks = getLinkTargets(occurrence, links) ]
    [#assign _context =
        {
            "Id" : fragment,
            "Name" : fragment,
            "Instance" : core.Instance.Id,
            "Version" : core.Version.Id,
            "DefaultEnvironment" : defaultEnvironment(occurrence, contextLinks),
            "Environment" : {},
            "Links" : contextLinks,
            "DefaultCoreVariables" : true,
            "DefaultEnvironmentVariables" : false,
            "DefaultLinkVariables" : true,
            "Policy" : [],
            "ManagedPolicy" : [],
            "Files" : {},
            "Directories" : {},
            "DataVolumes" : {}
        }
    ]

    [#-- Add in fragment specifics including override of defaults --]
    [#assign fragmentListMode = "model"]
    [#assign fragmentId = formatFragmentId(_context)]
    [#include fragmentList?ensure_starts_with("/")]

    [#assign environmentVariables += getFinalEnvironment(occurrence, _context).Environment ]

    [#assign configSets +=
        getInitConfigEnvFacts(environmentVariables, false) +
        getInitConfigDirsFiles(_context.Files, _context.Directories) ]

    [#list bootstrapProfile.BootStraps as bootstrapName ]
        [#assign bootstrap = bootstraps[bootstrapName]]
        [#assign configSets +=
            getInitConfigUserBootstrap(bootstrap, environmentVariables )!{}]
    [/#list]

    [#list links as linkId,link]
        [#assign linkTarget = getLinkTarget(occurrence, link) ]

        [@cfDebug listMode linkTarget false /]

        [#if !linkTarget?has_content]
            [#continue]
        [/#if]

        [#assign linkTargetCore = linkTarget.Core ]
        [#assign linkTargetConfiguration = linkTarget.Configuration ]
        [#assign linkTargetResources = linkTarget.State.Resources ]
        [#assign linkTargetAttributes = linkTarget.State.Attributes ]

        [#assign sourceSecurityGroupIds = []]
        [#assign sourceIPAddressGroups = [] ]

        [#switch linkTargetCore.Type]
            [#case LB_PORT_COMPONENT_TYPE]
                [#assign targetGroupPermission = true]
                [#assign destinationPort = linkTargetAttributes["DESTINATION_PORT"]]

                [#switch linkTargetAttributes["ENGINE"] ]
                    [#case "application" ]
                    [#case "classic"]
                        [#assign sourceSecurityGroupIds += [ linkTargetResources["sg"].Id ] ]
                        [#break]
                    [#case "network" ]
                        [#assign sourceIPAddressGroups = linkTargetConfiguration.IPAddressGroups + [ "_localnet" ] ]
                        [#break]
                [/#switch]

                [#switch linkTargetAttributes["ENGINE"]]

                    [#case "application"]
                    [#case "network"]
                        [#assign configSets += getInitConfigLBTargetRegistration(linkTargetCore.Id, linkTargetAttributes["TARGET_GROUP_ARN"])]

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

            [#case DATAVOLUME_COMPONENT_TYPE]
                [#assign linkVolumeResources = {}]
                [#list linkTargetResources["Zones"] as zoneId, linkZoneResources ]
                    [#assign linkVolumeResources += {
                        zoneId : {
                            "VolumeId" : linkZoneResources["ebsVolume"].Id
                        }
                    }]
                [/#list]
                [#assign _context +=
                    {
                        "DataVolumes" :
                            (_context.DataVolumes!{}) +
                            {
                                linkId : linkVolumeResources
                            }
                    }]
                [#break]
        [/#switch]

        [#if deploymentSubsetRequired(EC2_COMPONENT_TYPE, true)]

            [#assign securityGroupCIDRs = getGroupCIDRs(sourceIPAddressGroups, true, occurrence)]
            [#list securityGroupCIDRs as cidr ]

                [@createSecurityGroupIngress
                    mode=listMode
                    id=
                        formatDependentSecurityGroupIngressId(
                            ec2SecurityGroupId,
                            link.Id,
                            destinationPort,
                            replaceAlphaNumericOnly(cidr)
                        )
                    port=destinationPort
                    cidr=cidr
                    groupId=ec2SecurityGroupId
            /]
            [/#list]

            [#list sourceSecurityGroupIds as group ]
                [@createSecurityGroupIngress
                    mode=listMode
                    id=
                        formatDependentSecurityGroupIngressId(
                            ec2SecurityGroupId,
                            link.Id,
                            destinationPort
                        )
                    port=destinationPort
                    cidr=group
                    groupId=ec2SecurityGroupId
                /]
            [/#list]
        [/#if]
    [/#list]

    [#if deploymentSubsetRequired("iam", true) &&
            isPartOfCurrentDeploymentUnit(ec2RoleId)]

        [#assign linkPolicies = getLinkTargetsOutboundRoles(_context.Links) ]

        [@createRole
            mode=listMode
            id=ec2RoleId
            trustedServices=["ec2.amazonaws.com" ]
            managedArns=
                _context.ManagedPolicy
            policies=
                [
                    getPolicyDocument(
                        s3ListPermission(codeBucket) +
                        s3ReadPermission(codeBucket) +
                        s3ListPermission(operationsBucket) +
                        s3WritePermission(operationsBucket, "DOCKERLogs") +
                        s3WritePermission(operationsBucket, "Backups") +
                        cwLogsProducePermission(ec2LogGroupName) +
                        ec2EBSVolumeReadPermission(),
                        "basic")
                ] + targetGroupPermission?then(
                    [
                        getPolicyDocument(
                            lbRegisterTargetPermission(),
                            "loadbalancing")
                    ],
                    []
                ) +
                arrayIfContent(
                    [getPolicyDocument(linkPolicies, "links")],
                    linkPolicies) +
                arrayIfContent(
                    [getPolicyDocument(_context.Policy, "fragment")],
                    _context.Policy)
        /]
    [/#if]

    [#if deploymentSubsetRequired("lg", true) && isPartOfCurrentDeploymentUnit(ec2LogGroupId) ]
        [@createLogGroup
            mode=listMode
            id=ec2LogGroupId
            name=ec2LogGroupName /]
    [/#if]

    [#assign configSets +=
        getInitConfigLogAgent(
            logFileProfile,
            ec2LogGroupName
        )]

    [#if deploymentSubsetRequired("ec2", true)]

        [@createSecurityGroup
            mode=listMode
            id=ec2SecurityGroupId
            name=ec2SecurityGroupName
            occurrence=occurrence
            ingressRules=ingressRules
            vpcId=vpcId /]

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

                [#assign updateCommand = "yum clean all && yum -y update"]
                [#assign dailyUpdateCron = 'echo \"59 13 * * * ${updateCommand} >> /var/log/update.log 2>&1\" >crontab.txt && crontab crontab.txt']
                [#if environmentId == "prod"]
                    [#-- for production update only security packages --]
                    [#assign updateCommand += " --security"]
                    [#assign dailyUpdateCron = 'echo \"29 13 * * 6 ${updateCommand} >> /var/log/update.log 2>&1\" >crontab.txt && crontab crontab.txt']
                [/#if]

                [#-- Data Volume Mounts --]
                [#list _context.VolumeMounts as mountId,volumeMount ]
                    [#assign dataVolume = _context.DataVolumes[mountId]!{} ]
                    [#if dataVolume?has_content ]
                        [#assign zoneVolume = (dataVolume[zone.Id].VolumeId)!"" ]
                        [#if zoneVolume?has_content ]
                            [@createEBSVolumeAttachment
                                mode=listMode
                                id=formatDependentResourceId(AWS_EC2_EBS_ATTACHMENT_RESOURCE_TYPE,zoneEc2InstanceId,mountId)
                                device=volumeMount.DeviceId
                                instanceId=zoneEc2InstanceId
                                volumeId=zoneVolume
                            /]
                            [#assign configSets +=
                                getInitConfigDataVolumeMount(
                                    volumeMount.DeviceId
                                    volumeMount.MountPath
                                )
                            ]
                        [/#if]
                    [/#if]
                [/#list]

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
                        getOccurrenceCoreTags(
                            occurrence,
                            formatComponentFullName(core.Tier, core.Component, zone),
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
                            "SubnetId" : getSubnets(core.Tier, networkResources, zone.Id)[0],
                            "SourceDestCheck" : true,
                            "GroupSet" :
                                [getReference(ec2SecurityGroupId)] +
                                sshFromProxySecurityGroup?has_content?then(
                                    [sshFromProxySecurityGroup],
                                    []
                                )
                        }
                    tags=
                        getOccurrenceCoreTags(
                            occurrence,
                            formatComponentFullName(core.Tier, core.Component, zone, "eth0"),
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
[/#macro]