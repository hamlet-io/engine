[#ftl]
[#macro aws_ec2_cf_solution occurrence ]
    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["template"])
        /]
        [#return]
    [/#if]

    [@cfDebug listMode occurrence false /]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]
    [#local resources = occurrence.State.Resources]
    [#local zoneResources = occurrence.State.Resources.Zones]
    [#local links = solution.Links ]

    [#local fixedIP = solution.FixedIP]
    [#local dockerHost = solution.DockerHost]

    [#local ec2SecurityGroupId     = resources["sg"].Id]
    [#local ec2SecurityGroupName   = resources["sg"].Name]
    [#local ec2RoleId              = resources["ec2Role"].Id]
    [#local ec2InstanceProfileId   = resources["instanceProfile"].Id]
    [#local ec2LogGroupId          = resources["lg"].Id]
    [#local ec2LogGroupName        = resources["lg"].Name]

    [#local processorProfile       = getProcessor(occurrence, "EC2")]
    [#local storageProfile         = getStorage(occurrence, "EC2")]
    [#local logFileProfile         = getLogFileProfile(occurrence, "EC2")]
    [#local bootstrapProfile       = getBootstrapProfile(occurrence, "EC2")]

    [#local occurrenceNetwork = getOccurrenceNetwork(occurrence) ]
    [#local networkLink = occurrenceNetwork.Link!{} ]

    [#local networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]

    [#if ! networkLinkTarget?has_content ]
        [@cfException listMode "Network could not be found" networkLink /]
        [#return]
    [/#if]

    [#local networkConfiguration = networkLinkTarget.Configuration.Solution]
    [#local networkResources = networkLinkTarget.State.Resources ]

    [#local vpcId = networkResources["vpc"].Id ]

    [#local routeTableLinkTarget = getLinkTarget(occurrence, networkLink + { "RouteTable" : occurrenceNetwork.RouteTable })]
    [#local routeTableConfiguration = routeTableLinkTarget.Configuration.Solution ]
    [#local publicRouteTable = routeTableConfiguration.Public ]

    [#local targetGroupRegistrations = {}]
    [#local targetGroupPermission = false ]

    [#local environmentVariables = {}]

    [#local configSetName = occurrence.Core.Type]
    [#local configSets =
            getInitConfigDirectories() +
            getInitConfigBootstrap(occurrence) +
            getInitConfigPuppet() ]

    [#local efsMountPoints = {}]

    [#local componentDependencies = []]
    [#local ingressRules = []]

    [#list solution.Ports?values as port ]
        [#if port.LB.Configured]
            [#local lbLink = getLBLink(occurrence, port)]
            [#if isDuplicateLink(links, lbLink) ]
                [@cfException
                    mode=listMode
                    description="Duplicate Link Name"
                    context=links
                    detail=lbLink /]
                [#continue]
            [/#if]
            [#local links += lbLink]
        [#else]
            [#local portCIDRs = getGroupCIDRs(port.IPAddressGroups, true, occurrence) ]
            [#if portCIDRs?has_content]
                [#local ingressRules +=
                    [{
                        "Port" : port.Name,
                        "CIDR" : portCIDRs
                    }]]
            [/#if]
        [/#if]
    [/#list]

    [#local fragment = getOccurrenceFragmentBase(occurrence) ]

    [#local contextLinks = getLinkTargets(occurrence, links) ]
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
    [#local fragmentId = formatFragmentId(_context)]
    [#include fragmentList?ensure_starts_with("/")]

    [#local environmentVariables += getFinalEnvironment(occurrence, _context).Environment ]

    [#local configSets +=
        getInitConfigEnvFacts(environmentVariables, false) +
        getInitConfigDirsFiles(_context.Files, _context.Directories) ]

    [#list bootstrapProfile.BootStraps as bootstrapName ]
        [#local bootstrap = bootstraps[bootstrapName]]
        [#local configSets +=
            getInitConfigUserBootstrap(bootstrap, environmentVariables )!{}]
    [/#list]

    [#list links as linkId,link]
        [#local linkTarget = getLinkTarget(occurrence, link) ]

        [@cfDebug listMode linkTarget false /]

        [#if !linkTarget?has_content]
            [#continue]
        [/#if]

        [#local linkTargetCore = linkTarget.Core ]
        [#local linkTargetConfiguration = linkTarget.Configuration ]
        [#local linkTargetResources = linkTarget.State.Resources ]
        [#local linkTargetAttributes = linkTarget.State.Attributes ]

        [#local sourceSecurityGroupIds = []]
        [#local sourceIPAddressGroups = [] ]

        [#switch linkTargetCore.Type]
            [#case LB_PORT_COMPONENT_TYPE]
                [#local targetGroupPermission = true]
                [#local destinationPort = linkTargetAttributes["DESTINATION_PORT"]]

                [#switch linkTargetAttributes["ENGINE"] ]
                    [#case "application" ]
                    [#case "classic"]
                        [#local sourceSecurityGroupIds += [ linkTargetResources["sg"].Id ] ]
                        [#break]
                    [#case "network" ]
                        [#local sourceIPAddressGroups = linkTargetConfiguration.IPAddressGroups + [ "_localnet" ] ]
                        [#break]
                [/#switch]

                [#switch linkTargetAttributes["ENGINE"]]

                    [#case "application"]
                    [#case "network"]
                        [#local configSets += getInitConfigLBTargetRegistration(linkTargetCore.Id, linkTargetAttributes["TARGET_GROUP_ARN"])]

                        [#break]

                    [#case "classic" ]
                        [#local lbId =  linkTargetAttributes["LB"] ]
                        [#local configSets +=
                            getInitConfigLBClassicRegistration(lbId)]
                        [#break]
                    [/#switch]
                [#break]
            [#case EFS_MOUNT_COMPONENT_TYPE]
                [#local configSets +=
                    getInitConfigEFSMount(
                        linkTargetCore.Id,
                        linkTargetAttributes.EFS,
                        linkTargetAttributes.DIRECTORY,
                        link.Id
                    )]
                [#break]

            [#case DATAVOLUME_COMPONENT_TYPE]
                [#local linkVolumeResources = {}]
                [#list linkTargetResources["Zones"] as zoneId, linkZoneResources ]
                    [#local linkVolumeResources += {
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

            [#local securityGroupCIDRs = getGroupCIDRs(sourceIPAddressGroups, true, occurrence)]
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

        [#local linkPolicies = getLinkTargetsOutboundRoles(_context.Links) ]

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

    [#local configSets +=
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
                [#local zoneEc2InstanceId          = zoneResources[zone.Id]["ec2Instance"].Id ]
                [#local zoneEc2InstanceName        = zoneResources[zone.Id]["ec2Instance"].Name ]
                [#local zoneEc2ENIId               = zoneResources[zone.Id]["ec2ENI"].Id ]
                [#local zoneEc2EIPId               = zoneResources[zone.Id]["ec2EIP"].Id]
                [#local zoneEc2EIPAssociationId    = zoneResources[zone.Id]["ec2EIPAssociation"].Id]

                [#local updateCommand = "yum clean all && yum -y update"]
                [#local dailyUpdateCron = 'echo \"59 13 * * * ${updateCommand} >> /var/log/update.log 2>&1\" >crontab.txt && crontab crontab.txt']
                [#if environmentId == "prod"]
                    [#-- for production update only security packages --]
                    [#local updateCommand += " --security"]
                    [#local dailyUpdateCron = 'echo \"29 13 * * 6 ${updateCommand} >> /var/log/update.log 2>&1\" >crontab.txt && crontab crontab.txt']
                [/#if]

                [#-- Data Volume Mounts --]
                [#list _context.VolumeMounts as mountId,volumeMount ]
                    [#local dataVolume = _context.DataVolumes[mountId]!{} ]
                    [#if dataVolume?has_content ]
                        [#local zoneVolume = (dataVolume[zone.Id].VolumeId)!"" ]
                        [#if zoneVolume?has_content ]
                            [@createEBSVolumeAttachment
                                mode=listMode
                                id=formatDependentResourceId(AWS_EC2_EBS_ATTACHMENT_RESOURCE_TYPE,zoneEc2InstanceId,mountId)
                                device=volumeMount.DeviceId
                                instanceId=zoneEc2InstanceId
                                volumeId=zoneVolume
                            /]
                            [#local configSets +=
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