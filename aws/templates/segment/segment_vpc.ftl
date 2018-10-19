[#-- VPC --]

[#-- SSH and NAT should now be configured as separate deployment units but  --]
[#-- the code supports legacy installations where they were part of the vpc --]
[#-- TODO: Remove extra checks on ssh and nat when all legacy instances are --]
[#-- retired --]

[#-- TODO: change to formatVPCId() when all legacy installations are retired --]
[#assign vpcId = formatVPCTemplateId() ]

[#if componentType == "vpc"]
    [#-- TODO: change to formatVPCIGWId() when all legacy installations are retired --]
    [#assign igwId = formatVPCIGWTemplateId() ]

    [#assign topicId = formatSegmentSNSTopicId() ]
    [#assign dashboardId = formatSegmentCWDashboardId() ]

    [#assign flowLogsRoleId = formatDependentRoleId(vpcId) ]
    [#assign flowLogsAllId = formatVPCFlowLogsId("all") ]
    [#assign flowLogsAllLogGroupId = formatDependentLogGroupId(vpcId, "all") ]
    [#assign flowLogsAllLogGroupName = formatSegmentLogGroupName("vpcflowlogs", "all") ]

    [#if deploymentSubsetRequired("iam", true) &&
            isPartOfCurrentDeploymentUnit(flowLogsRoleId)]
        [@createRole
            mode=listMode
            id=flowLogsRoleId
            trustedServices=["vpc-flow-logs.amazonaws.com"]
            policies=
                [
                    getPolicyDocument(
                        cwLogsProducePermission(),
                        formatName("vpcflowlogs"))
                ]
        /]
    [/#if]

    [#if deploymentSubsetRequired("lg", true) &&
            isPartOfCurrentDeploymentUnit(flowLogsAllLogGroupId)]
        [@createVPCLogGroup
            mode=listMode
            id=flowLogsAllLogGroupId
            name=flowLogsAllLogGroupName
            retention=((segmentObject.Operations.FlowLogs.Expiration) !
                        (segmentObject.Operations.Expiration) !
                        (environmentObject.Operations.FlowLogs.Expiration) !
                        (environmentObject.Operations.Expiration) ! 7)
        /]
    [/#if]

    [#if deploymentSubsetRequired("vpc", true)]
        [#if (segmentObject.Operations.FlowLogs.Enabled)!
                (environmentObject.Operations.FlowLogs.Enabled)! false]
            [@createVPCFlowLog
                mode=listMode
                id=flowLogsAllId
                vpcId=vpcId
                roleId=flowLogsRoleId
                logGroupName=flowLogsAllLogGroupName
                trafficType="ALL"
            /]
        [/#if]

        [@createSegmentSNSTopic
            mode=listMode
            id=topicId
        /]

        [@createVPC
            mode=listMode
            id=vpcId
            name=formatVPCName()
            cidr=segmentObject.Network.CIDR.Address + "/" + segmentObject.Network.CIDR.Mask
            dnsSupport=dnsSupport
            dnsHostnames=dnsHostnames
        /]

        [#if internetAccess]
            [@createIGW
                mode=listMode
                id=igwId
                name=formatIGWName()
            /]
            [@createIGWAttachment
                mode=listMode
                id=formatId("igw","attachment")
                vpcId=vpcId
                igwId=igwId
            /]
        [/#if]

        [#-- Define route tables --]
        [#assign solutionRouteTables = []]
        [#list segmentObject.Network.Tiers.Order as tierId]
            [#assign networkTier = getTier(tierId) ]
            [#if ! (networkTier?has_content) ]
                [#continue]
            [/#if]
            [#assign routeTable = routeTables[networkTier.Network.RouteTable]]
            [#list zones as zone]
                [#assign routeTableId = formatRouteTableId(routeTable,natPerAZ?string(zone.Id,""))]
                [#assign routeTableName = formatRouteTableName(routeTable,natPerAZ?string(zone.Id,""))]
                [#if !solutionRouteTables?seq_contains(routeTableId)]
                    [#assign solutionRouteTables += [routeTableId]]
                    [@createRouteTable
                        mode=listMode
                        id=routeTableId
                        name=routeTableName
                        vpcId=vpcId
                        zone=natPerAZ?then(zone,"")
                    /]
                    [#list routeTable.Routes?values as route]
                        [#if route?is_hash]
                            [#switch route.Type!""]
                                [#case "gateway"]
                                    [#if internetAccess]
                                        [@createRoute
                                            mode=listMode
                                            id=formatRouteId(routeTableId, route)
                                            routeTableId=routeTableId
                                            route=
                                                route +
                                                {
                                                    "IgwId" : igwId,
                                                    "CIDR" : "0.0.0.0/0"
                                                }
                                        /]
                                    [/#if]
                                    [#break]
                            [/#switch]
                        [/#if]
                    [/#list]
                [/#if]
            [/#list]
        [/#list]

        [#-- Define the VPC endpoints --]
        [#-- They are free so seems logical to always create them --]
        [#-- For now we use the default (open) policy that comes  --]
        [#-- by default with the endpoint                         --]
        [#list ["s3", "dynamodb"] as service]
            [@createVPCEndpoint
                mode=listMode
                id=formatVPCEndPointId(service)
                vpcId=vpcId
                service=service
                routeTableIds=solutionRouteTables
            /]
        [/#list]

        [#-- Define network ACLs --]
        [#assign solutionNetworkACLs = []]
        [#list segmentObject.Network.Tiers.Order as tierId]
            [#assign networkTier = getTier(tierId) ]
            [#if ! (networkTier?has_content) ]
                [#continue]
            [/#if]
            [#assign networkACL = networkACLs[networkTier.Network.NetworkACL]]
            [#assign networkACLId = formatNetworkACLId(networkACL)]
            [#assign networkACLName = formatNetworkACLName(networkACL)]
            [#if !solutionNetworkACLs?seq_contains(networkACLId)]
                [#assign solutionNetworkACLs += [networkACLId]]
                [@createNetworkACL
                    mode=listMode
                    id=networkACLId
                    name=networkACLName
                    vpcId=vpcId
                /]
                [#list ["Inbound", "Outbound"] as direction]
                    [#if networkACL.Rules[direction]??]
                        [#list networkACL.Rules[direction]?values as rule]
                            [#if rule?is_hash]
                                [#assign networkACLEntryId =
                                            formatNetworkACLEntryId(
                                                networkACLId,
                                                (direction=="Outbound"),
                                                rule)]
                                [@createNetworkACLEntry
                                    mode=listMode
                                    id=networkACLEntryId
                                    networkACLId=networkACLId
                                    outbound=(direction=="Outbound")
                                    rule=rule
                                /]
                            [/#if]
                        [/#list]
                    [/#if]
                [/#list]
            [/#if]
        [/#list]

        [#-- Define subnets --]
        [#list segmentObject.Network.Tiers.Order as tierId]
            [#assign networkTier = getTier(tierId) ]
            [#if ! (networkTier?has_content) ]
                [#continue]
            [/#if]
            [#assign routeTable = routeTables[networkTier.Network.RouteTable]]
            [#assign networkACL = networkACLs[networkTier.Network.NetworkACL]]
            [#list zones as zone]
                [#assign networkACLId = formatNetworkACLId(networkACL)]
                [#assign routeTableId = formatRouteTableId(routeTable,natPerAZ?string(zone.Id,""))]
                [#assign subnetId = formatSubnetId(networkTier, zone)]
                [#assign subnetName = formatSubnetName(networkTier, zone)]
                [#assign subnetAddress = addressOffset + (networkTier.Network.Index * addressesPerTier) + (zone.Index * addressesPerZone)]
                [#assign routeTableAssociationId = formatRouteTableAssociationId(subnetId)]
                [#assign networkACLAssociationId = formatNetworkACLAssociationId(subnetId)]
                [@createSubnet
                    mode=listMode
                    id=subnetId
                    name=subnetName
                    vpcId=vpcId
                    tier=networkTier
                    zone=zone
                    cidr=baseAddress[0] + "." + baseAddress[1] + "." + (subnetAddress/256)?int + "." + subnetAddress%256 + "/" + subnetMask
                    private=routeTable.Private!false
                /]
                [@createRouteTableAssociation
                    mode=listMode
                    id=routeTableAssociationId
                    subnetId=subnetId
                    routeTableId=routeTableId
                /]
                [@createNetworkACLAssociation
                    mode=listMode
                    id=networkACLAssociationId
                    subnetId=subnetId
                    networkACLId=networkACLId
                /]
            [/#list]
        [/#list]

    [/#if]

[/#if]

[#-- NAT --]

[#assign allToNATSecurityGroupId = formatComponentSecurityGroupId(tier, "nat", "all")]

[#assign natInVpc =
    (getExistingReference(allToNATSecurityGroupId, "", "", "vpc")?has_content) ||
    (getExistingReference(formatNATGatewayId(tier, zones[0]), "", "", "vpc")?has_content)
]

[#if natEnabled &&
    (
        (componentType == "nat") ||
        ((componentType == "vpc") && natInVpc)
    )]

    [#assign natComponent =
        natInVpc?then(
            {
                "Id" : "nat",
                "Name" : "nat"
            },
            component
        )
    ]

    [#assign roleId = formatComponentRoleId(tier, natComponent)]

    [#if deploymentSubsetRequired("iam", true) &&
            isPartOfCurrentDeploymentUnit(roleId) &&
            (!natHosted)]
        [@createRole
            mode=listMode
            id=roleId
            trustedServices=["ec2.amazonaws.com" ]
            policies=
                [
                    getPolicyDocument(
                        ec2IPAddressUpdatePermission() +
                            ec2SubnetReadPermission() +
                            ec2RouteAllPermission() +
                            ec2InstanceUpdatePermission() +
                            s3ListPermission(codeBucket) +
                            s3ReadPermission(codeBucket),
                        "nat")
                ]
        /]
    [/#if]

    [#if deploymentSubsetRequired("eip", true)]
        [#list zones as zone]
            [#if natPerAZ || zone?is_first]
                [#assign eipId = formatComponentEIPId(tier, natComponent, zone)]
                [#if isPartOfCurrentDeploymentUnit(eipId)]
                    [@createEIP
                        mode=listMode
                        id=eipId
                    /]
                [/#if]
            [/#if]
        [/#list]
    [/#if]

    [#if deploymentSubsetRequired("nat", true)]
        [#if !natHosted]
            [#assign instanceProfileId = formatEC2InstanceProfileId(tier, natComponent)]

            [@cfResource
                mode=listMode
                id=instanceProfileId
                type="AWS::IAM::InstanceProfile"
                properties=
                    {
                        "Path" : "/",
                        "Roles" : [ getReference(roleId) ]
                    }
                outputs={}
            /]

            [@createSecurityGroup
                mode=listMode
                tier=tier
                component=natComponent
                id=allToNATSecurityGroupId
                name=formatComponentFullName(tier, natComponent)
                description="Security Group for outbound traffic to the NAT"
                ingressRules=
                    [
                        {
                            "Port" : "all",
                            "CIDR" : [segmentObject.Network.CIDR.Address + "/" + segmentObject.Network.CIDR.Mask]
                        }
                    ]
                vpcId=natInVpc?then(vpcId,"")
            /]
        [/#if]
        [#list zones as zone]
            [#if natPerAZ || zone?is_first]
                [#assign eipId = formatComponentEIPId(tier, natComponent, zone)]
                [#if natHosted]
                    [#assign natGatewayId = formatNATGatewayId(tier, zone)]
                    [@createNATGateway
                        mode=listMode
                        id=natGatewayId
                        name=formatComponentFullName(tier, natComponent, zone)
                        tier=tier
                        component=natComponent
                        zone=zone
                        subnetId=formatSubnetId(tier, zone)
                        eipId=eipId
                    /]
                    [#assign updatedRouteTables = []]
                    [#list segmentObject.Network.Tiers.Order as tierId]
                        [#assign networkTier = getTier(tierId) ]
                        [#if ! (networkTier?has_content) ]
                            [#continue]
                        [/#if]
                        [#assign routeTable = routeTables[networkTier.Network.RouteTable]]
                        [#if routeTable.Private!false]
                            [#assign routeTableId = formatRouteTableId(routeTable,natPerAZ?string(zone.Id,""))]
                            [#if !updatedRouteTables?seq_contains(routeTableId)]
                                [#assign updatedRouteTables += [routeTableId]]
                                [@createRoute
                                    mode=listMode
                                    id=formatRouteId(routeTableId, "natgateway")
                                    routeTableId=routeTableId
                                    route=
                                        {
                                            "Type" : "nat",
                                            "CIDR" : "0.0.0.0/0",
                                            "NatId" : natGatewayId
                                        }
                                /]
                            [/#if]
                        [/#if]
                    [/#list]
                [#else]
                    [#assign asgId = formatEC2AutoScaleGroupId(tier, natComponent, zone)]
                    [#assign launchConfigId = formatEC2LaunchConfigId(tier, natComponent, zone)]

                    [#assign natCommands =
                        {
                            "01ExecuteRouteUpdateScript" : {
                                "command" : "/opt/codeontap/bootstrap/nat.sh",
                                "ignoreErrors" : "false"
                            },
                            "02ExecuteAllocateEIPScript" : {
                                "command" : "/opt/codeontap/bootstrap/eip.sh",
                                "env" : {
                                    "EIP_ALLOCID" :
                                        getReference(
                                            eipId,
                                            ALLOCATION_ATTRIBUTE_TYPE
                                        )
                                },
                                "ignoreErrors" : "false"
                            }
                        }
                    ]

                    [@cfResource
                        mode=listMode
                        id=asgId
                        type="AWS::AutoScaling::AutoScalingGroup"
                        dependencies=formatSubnetId(tier, zone)
                        metadata=
                            {
                                "AWS::CloudFormation::Init": {
                                    "configSets" : {
                                        "nat" : ["dirs", "bootstrap", "nat"]
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
                                                            "echo \"cot:request="       + requestReference       + "\"\n",
                                                            "echo \"cot:configuration=" + configurationReference + "\"\n",
                                                            "echo \"cot:accountRegion=" + accountRegionId        + "\"\n",
                                                            "echo \"cot:tenant="        + tenantId               + "\"\n",
                                                            "echo \"cot:account="       + accountId              + "\"\n",
                                                            "echo \"cot:product="       + productId              + "\"\n",
                                                            "echo \"cot:region="        + regionId               + "\"\n",
                                                            "echo \"cot:segment="       + segmentId              + "\"\n",
                                                            "echo \"cot:environment="   + environmentId          + "\"\n",
                                                            "echo \"cot:tier="          + tier.Id                + "\"\n",
                                                            "echo \"cot:component="     + "nat"                  + "\"\n",
                                                            "echo \"cot:zone="          + zone.Id                + "\"\n",
                                                            "echo \"cot:role="          + "nat"                  + "\"\n",
                                                            "echo \"cot:credentials="   + credentialsBucket      + "\"\n",
                                                            "echo \"cot:code="          + codeBucket             + "\"\n",
                                                            "echo \"cot:logs="          + operationsBucket       + "\"\n",
                                                            "echo \"cot:backups="       + dataBucket             + "\"\n"
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
                                        }
                                    },
                                    "nat": {
                                        "commands": natCommands
                                    }
                                }
                            }
                        properties=
                            {
                                "Cooldown" : "30",
                                "LaunchConfigurationName": getReference(launchConfigId),
                                "MinSize": "1",
                                "MaxSize": "1",
                                "VPCZoneIdentifier": [ getReference(formatSubnetId(tier, zone)) ]
                            }
                        tags=
                            getCfTemplateCoreTags(
                                formatComponentFullName(tier, netComponent, zone),
                                tier,
                                netComponent,
                                zone,
                                true)
                    /]

                    [#assign processorProfile = getProcessor(tier, natComponent, "NAT")]
                    [#assign updateCommand = "yum clean all && yum -y update"]
                    [#assign dailyUpdateCron = 'echo \"59 13 * * * ${updateCommand} >> /var/log/update.log 2>&1\" >crontab.txt && crontab crontab.txt']
                    [#if environmentId == "prod"]
                        [#-- for production update only security packages --]
                        [#assign updateCommand += " --security"]
                        [#assign dailyUpdateCron = 'echo \"29 13 * * 6 ${updateCommand} >> /var/log/update.log 2>&1\" >crontab.txt && crontab crontab.txt']
                    [/#if]
                    [#-- daily cron record for updates --]
                    [@cfResource
                        mode=listMode
                        id=launchConfigId
                        type="AWS::AutoScaling::LaunchConfiguration"
                        properties=
                            {
                                "KeyName": getExistingReference(formatEC2KeyPairId(), NAME_ATTRIBUTE_TYPE),
                                "ImageId": regionObject.AMIs.Centos.NAT,
                                "InstanceType": processorProfile.Processor,
                                "SecurityGroups" : (sshEnabled && !sshStandalone)?then(
                                                        [
                                                            getReference(sshToProxySecurityGroupId),
                                                            getReference(allToNATSecurityGroupId)
                                                        ],
                                                        [
                                                            getReference(allToNATSecurityGroupId)
                                                        ]
                                                    ),
                                "IamInstanceProfile" : getReference(instanceProfileId),
                                "AssociatePublicIpAddress": true,
                                "UserData": {
                                    "Fn::Base64": {
                                        "Fn::Join": [
                                            "",
                                            [
                                                "#!/bin/bash -ex\n",
                                                "exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1\n",
                                                updateCommand, "\n",
                                                dailyUpdateCron, "\n",
                                                "yum install -y aws-cfn-bootstrap\n",
                                                "# Remainder of configuration via metadata\n",
                                                "/opt/aws/bin/cfn-init -v",
                                                " --stack ", { "Ref" : "AWS::StackName" },
                                                " --resource " + asgId,
                                                " --region " + regionId + " --configsets nat\n"
                                            ]
                                        ]
                                    }
                                }
                            }
                        outputs={}
                    /]
                [/#if]
            [/#if]
        [/#list]
    [/#if]
[/#if]



