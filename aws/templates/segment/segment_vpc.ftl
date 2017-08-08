[#-- Define VPC --]
[#if deploymentUnit?contains("vpc")]
    [#assign vpcId = formatVPCTemplateId() ]
    [#assign igwId = formatVPCIGWTemplateId() ]

    [#assign topicId = formatSegmentSNSTopicId() ]
    [#assign dashboardId = formatSegmentCWDashboardId() ]

    [#assign flowLogsRoleId = formatDependentRoleId(vpcId) ]
    [#assign flowLogsAllId = formatVPCFlowLogsId("all") ]
    [#assign flowLogsAllLogGroupId = formatDependentLogGroupId(vpcId, "all") ]
    [#assign flowLogsAllLogGroupName = formatSegmentLogGroupName("vpcflowlogs", "all") ]

    [#assign mgmtTier = getTier("mgmt")]
    [#assign sshFromProxySecurityGroupId = formatSSHFromProxySecurityGroupId()]
    [#assign sshToProxySecurityGroupId = formatComponentSecurityGroupId(mgmtTier, "ssh")]
    [#assign allToNATSecurityGroupId = formatComponentSecurityGroupId(mgmtTier, "nat", "all")]

    [#if deploymentSubsetRequired("flowlogs", true) && isPartOfCurrentDeploymentUnit(flowLogsRoleId)]
        [#switch segmentListMode]
            [#case "definition"]
                [@checkIfResourcesCreated /]
                [@roleHeader flowLogsRoleId, ["vpc-flow-logs.amazonaws.com"] /]
                    [@policyHeader formatName("vpcflowlogs") /]
                        [@cloudWatchLogsProduceStatement /]
                    [@policyFooter /]
                [@roleFooter /]
                [@resourcesCreated /]
                [#break]
        
            [#case "outputs"]
                [@output flowLogsRoleId /]
                [@outputArn flowLogsRoleId /]
                [#break]
        
        [/#switch]
        [@createVPCLogGroup
            segmentListMode,
            flowLogsAllLogGroupId,
            flowLogsAllLogGroupName,
            (segmentObject.Operations.FlowLogs.Expiration) !
                (segmentObject.Operations.Expiration) !
            (environmentObject.Operations.FlowLogs.Expiration) !
                (environmentObject.Operations.Expiration) ! 7 /]
    [/#if]
        
    [#if deploymentSubsetRequired("vpc", true)]
        [#if (segmentObject.Operations.FlowLogs.Enabled)!
                (environmentObject.Operations.FlowLogs.Enabled)! false]
            [@createVPCFlowLog
                segmentListMode,
                flowLogsAllId,
                vpcId,
                flowLogsRoleId,
                flowLogsAllLogGroupName,
                "ALL" /]
        [/#if]
            
        [@createSegmentSNSTopic segmentListMode topicId /]

        [@createVPC 
            segmentListMode
            vpcId,
            formatVPCName(),
            segmentObject.CIDR.Address + "/" + segmentObject.CIDR.Mask,
            dnsSupport,
            dnsHostnames /]

        [#if internetAccess]
            [@createIGW
                segmentListMode
                igwId
                formatIGWName() /]
            [@createIGWAttachment
                segmentListMode
                formatId("igw","attachment")
                vpcId
                igwId /]
        [/#if]
        
        [#-- Define route tables --]
        [#assign solutionRouteTables = []]
        [#list tiers as tier]
            [#assign routeTable = routeTables[tier.RouteTable]]
            [#list zones as zone]
                [#assign routeTableId = formatRouteTableId(routeTable,natPerAZ?string(zone.Id,""))]
                [#assign routeTableName = formatRouteTableName(routeTable,natPerAZ?string(zone.Id,""))]
                [#if !solutionRouteTables?seq_contains(routeTableId)]
                    [#assign solutionRouteTables += [routeTableId]]
                    [@createRouteTable
                        segmentListMode,
                        routeTableId,
                        routeTableName,
                        vpcId,
                        natPerAZ?then(zone,"")
                    /]
                    [#list routeTable.Routes?values as route]
                        [#if route?is_hash]
                            [@createRoute
                                segmentListMode,
                                formatRouteId(routeTableId, route),
                                routeTableId,
                                route + {"IgwId" : igwId, "CIDR" : "0.0.0.0/0"}
                            /]
                        [/#if]
                    [/#list]
                [/#if]
            [/#list]
        [/#list]
 
        [#-- Define network ACLs --]
        [#assign solutionNetworkACLs = []]
        [#list tiers as tier]
            [#assign networkACL = networkACLs[tier.NetworkACL]]
            [#assign networkACLId = formatNetworkACLId(networkACL)]
            [#assign networkACLName = formatNetworkACLName(networkACL)]
            [#if !solutionNetworkACLs?seq_contains(networkACLId)]
                [#assign solutionNetworkACLs += [networkACLId]]
                [@createNetworkACL
                    segmentListMode,
                    networkACLId,
                    networkACLName,
                    vpcId
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
                                    segmentListMode,
                                    networkACLEntryId,
                                    networkACLId,
                                    (direction=="Outbound"),
                                    rule
                                /]
                            [/#if]
                        [/#list]
                    [/#if]
                [/#list]
            [/#if]
        [/#list]
    
        [#-- Define subnets --]
        [#list tiers as tier]
            [#assign routeTable = routeTables[tier.RouteTable]]
            [#assign networkACL = networkACLs[tier.NetworkACL]]
            [#list zones as zone]
                [#assign networkACLId = formatNetworkACLId(networkACL)]
                [#assign routeTableId = formatRouteTableId(routeTable,natPerAZ?string(zone.Id,""))]
                [#assign subnetId = formatSubnetId(tier, zone)]
                [#assign subnetName = formatSubnetName(tier, zone)]
                [#assign subnetAddress = addressOffset + (tier.Index * addressesPerTier) + (zone.Index * addressesPerZone)]
                [#assign routeTableAssociationId = formatRouteTableAssociationId(subnetId)]
                [#assign networkACLAssociationId = formatNetworkACLAssociationId(subnetId)]
                [@createSubnet
                    segmentListMode,
                    subnetId,
                    subnetName,
                    vpcId,
                    tier,
                    zone,
                    baseAddress[0] + "." + baseAddress[1] + "." + (subnetAddress/256)?int + "." + subnetAddress%256 + "/" + subnetMask,
                    routeTable.Private!false
                /]
                [@createRouteTableAssociation
                    segmentListMode,
                    routeTableAssociationId,
                    subnetId,
                    routeTableId
                /]
                [@createNetworkACLAssociation
                    segmentListMode,
                    networkACLAssociationId,
                    subnetId,
                    networkACLId
                /]
            [/#list]
        [/#list]
                            
        [#if sshEnabled]
            [@createSecurityGroup
                segmentListMode,
                mgmtTier,
                "ssh",
                sshToProxySecurityGroupId,
                formatName(productName, segmentName, mgmtTier, "ssh"),
                "Security Group for inbound SSH to the SSH Proxy",
                [
                    {
                        "Port" : "ssh",
                        "CIDR" : (sshActive || sshStandalone)?then(
                                    getUsageCIDRs(
                                        "ssh",
                                        (segmentObject.SSH.IPAddressGroups)!
                                            segmentObject.IPAddressGroups![]),
                                    [])
                    }
                ]
            /]

            [@createSecurityGroup
                segmentListMode,
                "all",
                "ssh",
                sshFromProxySecurityGroupId,
                formatName(productName, segmentName, "all", "ssh"),
                "Security Group for SSH access from the SSH Proxy",
                [
                    {
                        "Port" : "ssh",
                        "CIDR" : [sshToProxySecurityGroupId]
                    }
                ]
            /]
            
            [#if sshStandalone]
                [#assign roleId = formatId("role", mgmtTier, "ssh")]
                [#assign instanceProfileId = formatId("instanceProfile", mgmtTier, "ssh")]
                [#switch segmentListMode]
                    [#case "definition"]
                        [@roleHeader roleId, ["ec2.amazonaws.com" ] /]
                            [@policyHeader formatName(mgmtTier.Id, "ssh") /]
                                [@IPAddressUpdateStatement /]
                                [@s3ListStatement codeBucket /]
                                [@s3ReadStatement codeBucket /]
                            [@policyFooter /]
                        [@roleFooter /]
                        [#break]
                [/#switch]

                [@cfTemplate
                    segmentListMode,
                    instanceProfileId,
                    "AWS::IAM::InstanceProfile",
                    {
                        "Path" : "/",
                        "Roles" : [ 
                            { "Ref" : roleId }
                        ]
                    },
                    []
                /]
                
                [#assign mgmtSubnetIds = []]
                [#assign mgmtSubnetRefs = []]
                [#list zones as zone]
                    [#assign subnetId = formatSubnetId(mgmtTier, zone)]
                    [#assign mgmtSubnetIds += [subnetId]]
                    [#assign mgmtSubnetRefs += [getReference(subnetId)]]
                [/#list]
                
                [#assign asgId = formatId("asg", mgmtTier, "ssh")]
                [#assign launchConfigId = formatId("launchConfig", mgmtTier, "ssh")]

                [@cfTemplate
                    mode=segmentListMode
                    id=asgId
                    type="AWS::AutoScaling::AutoScalingGroup"
                    dependencies=mgmtSubnetIds
                    metadata={
                        "AWS::CloudFormation::Init": {
                            "configSets" : {
                                "ssh" : ["dirs", "bootstrap", "ssh"]
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
                                                    "echo \\\"cot:tier="          + mgmtTier.Id            + "\\\"\\n",
                                                    "echo \\\"cot:component="     + "ssh"                  + "\\\"\\n",
                                                    "echo \\\"cot:role="          + "ssh"                  + "\\\"\\n",
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
                                }
                            },
                            "ssh": {
                                "commands": {
                                    "01ExecuteAllocateEIPScript" : {
                                        "command" : "/opt/codeontap/bootstrap/eip.sh",
                                        "env" : { 
                                            [#-- Normally assume eip defined in a separate template to the vpc --]
                                            "EIP_ALLOCID" : getKey(formatComponentEIPAllocationId(mgmtTier, "ssh"))
                                        },
                                        "ignoreErrors" : "false"
                                    }
                                }
                            }
                        }
                    }
                    properties={
                        "Cooldown" : "30",
                        "LaunchConfigurationName": {"Ref": launchConfigId },
                        "MinSize": sshActive?then("1","0"),
                        "MaxSize": sshActive?then("1","0"),
                        "VPCZoneIdentifier": mgmtSubnetRefs
                    }
                    tags=cfTemplateCoreTags(
                            formatComponentFullName(mgmtTier, "ssh"),
                            mgmtTier,
                            "ssh",
                            "",
                            true)
                /]
            
                [#assign component = { "Id" : ""}]
                [#assign processorProfile = getProcessor(mgmtTier, component, "SSH")]
                [@cfTemplate
                    mode=segmentListMode
                    id=launchConfigId
                    type="AWS::AutoScaling::LaunchConfiguration"
                    properties={
                        "KeyName": productName + sshPerSegment?string("-" + segmentName,""),
                        "ImageId": regionObject.AMIs.Centos.EC2,
                        "InstanceType": processorProfile.Processor,
                        "SecurityGroups" :
                            [
                                { "Ref": sshToProxySecurityGroupId }
                            ],
                        "IamInstanceProfile" : { "Ref" : instanceProfileId },
                        "AssociatePublicIpAddress": true,
                        "UserData": {
                            "Fn::Base64": { 
                                "Fn::Join": [ 
                                    "", 
                                    [
                                        "#!/bin/bash -ex\\n",
                                        "exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1\\n",
                                        "yum install -y aws-cfn-bootstrap\\n",
                                        "# Remainder of configuration via metadata\\n",
                                        "/opt/aws/bin/cfn-init -v",
                                        " --stack ", { "Ref" : "AWS::StackName" },
                                        " --resource " + asgId,
                                        " --region " + regionId + " --configsets ssh\\n"
                                    ]
                                ]
                            }
                        }
                    }
                    outputs=[]
                /]
            [/#if]
        [/#if]

        [#if natEnabled]
            [#if natHosted]
                [#list zones as zone]
                    [#if natPerAZ || zone?is_first]
                        [#assign natGatewayId = formatNATGatewayId(mgmtTier, zone)]
                        [@createNATGateway
                            segmentListMode,
                            natGatewayId,
                            formatSubnetId(mgmtTier, zone),
                            formatComponentEIPId(mgmtTier, "nat", zone)
                        /]
                        [#assign updatedRouteTables = []]
                        [#list tiers as tier]
                            [#assign routeTable = routeTables[tier.RouteTable]]
                            [#if routeTable.Private!false]
                                [#assign routeTableId = formatRouteTableId(routeTable,natPerAZ?string(zone.Id,""))]
                                [#if !updatedRouteTables?seq_contains(routeTableId)]
                                    [#assign updatedRouteTables += [routeTableId]]
                                    [@createRoute
                                        segmentListMode,
                                        formatRouteId(routeTableId, "natgateway"),
                                        routeTableId,
                                        {
                                            "Type" : "nat",
                                            "CIDR" : "0.0.0.0/0",
                                            "NatId" : natGatewayId
                                        }
                                    /]
                                [/#if]
                            [/#if]
                        [/#list]
                    [/#if]
                [/#list]
            [#else]
                [#assign roleId = formatId("role", mgmtTier, "nat")]
                [#assign instanceProfileId = formatId("instanceProfile", mgmtTier, "nat")]
                [#switch segmentListMode]
                    [#case "definition"]
                        [@roleHeader roleId, ["ec2.amazonaws.com" ] /]
                            [@policyHeader formatName(mgmtTier.Id, "nat") /]
                                [@IPAddressUpdateStatement /]
                                [@subnetReadStatement /]
                                [@routeAllStatement /]
                                [@instanceUpdateStatement /]
                                [@s3ListStatement codeBucket /]
                                [@s3ReadStatement codeBucket /]
                            [@policyFooter /]
                        [@roleFooter /]
                        [#break]
                [/#switch]

                [@cfTemplate
                    segmentListMode,
                    instanceProfileId,
                    "AWS::IAM::InstanceProfile",
                    {
                        "Path" : "/",
                        "Roles" : [ 
                            { "Ref" : roleId }
                        ]
                    },
                    []
                /]
                [@createSecurityGroup
                    segmentListMode,
                    mgmtTier,
                    "nat",
                    allToNATSecurityGroupId,
                    formatName(productName, segmentName, mgmtTier, "nat"),
                    "Security Group for outbound traffic to the NAT",
                    [
                        {
                            "Port" : "all",
                            "CIDR" : [segmentObject.CIDR.Address + "/" + segmentObject.CIDR.Mask]
                        }
                    ]
                /]
                        
                [#list zones as zone]
                    [#if natPerAZ || zone?is_first]
                        [#assign asgId = formatId("asg", mgmtTier, "nat", zone)]
                        [#assign launchConfigId = formatId("launchConfig", mgmtTier, "nat", zone)]
                        [#assign natCommands =
                            {
                                "01ExecuteRouteUpdateScript" : {
                                    "command" : "/opt/codeontap/bootstrap/nat.sh",
                                    "ignoreErrors" : "false"
                                }
                            }]
                        [#if deploymentUnit?contains("eip")]
                            [#assign natCommands +=
                                {
                                    "02ExecuteAllocateEIPScript" : {
                                        "command" : "/opt/codeontap/bootstrap/eip.sh",
                                        "env" : { 
                                            [#-- Legacy code to support definition of eip and vpc in one template (deploymentUnit = "eipvpc" or "eips3vpc" depending on how S3 to be defined)  --]
                                            "EIP_ALLOCID" : { "Fn::GetAtt" : [formatComponentEIPId(mgmtTier, "nat", zone), "AllocationId"] }
                                        },
                                        "ignoreErrors" : "false"
                                    }
                                }]
                        [#else]
                            [#assign eipAllocationId = getKey(formatComponentEIPAllocationId(mgmtTier, "nat", zone))]
                            [#if eipAllocationId?has_content]
                                [#assign natCommands +=
                                    {
                                        "02ExecuteAllocateEIPScript" : {
                                            "command" : "/opt/codeontap/bootstrap/eip.sh",
                                            "env" : { 
                                                [#-- Normally assume eip defined in a separate template to the vpc --]
                                                "EIP_ALLOCID" : eipAllocationId
                                            },
                                            "ignoreErrors" : "false"
                                        }
                                    }]
                            [/#if]
                        [/#if]

                        [@cfTemplate
                            mode=segmentListMode
                            id=asgId
                            type="AWS::AutoScaling::AutoScalingGroup"
                            dependencies=[ formatSubnetId(mgmtTier, zone) ]
                            metadata={
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
                                                            "echo \\\"cot:tier="          + mgmtTier.Id            + "\\\"\\n",
                                                            "echo \\\"cot:component="     + "nat"                  + "\\\"\\n",
                                                            "echo \\\"cot:zone="          + zone.Id                + "\\\"\\n",
                                                            "echo \\\"cot:role="          + "nat"                  + "\\\"\\n",
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
                                        }
                                    },
                                    "nat": {
                                        "commands": natCommands
                                    }
                                }
                            }
                            properties={
                                "Cooldown" : "30",
                                "LaunchConfigurationName": {"Ref": launchConfigId },
                                "MinSize": "1",
                                "MaxSize": "1",
                                "VPCZoneIdentifier": [ 
                                    { "Ref" : formatSubnetId(mgmtTier, zone)}
                                ]
                            }
                            tags=cfTemplateCoreTags(
                                    formatComponentFullName(mgmtTier, "nat", zone),
                                    mgmtTier,
                                    "nat",
                                    zone,
                                    true)
                        /]
                    
                        [#assign component = { "Id" : ""}]
                        [#assign processorProfile = getProcessor(mgmtTier, component, "NAT")]
                        [@cfTemplate
                            mode=segmentListMode
                            id=launchConfigId
                            type="AWS::AutoScaling::LaunchConfiguration"
                            properties={
                                "KeyName": productName + sshPerSegment?string("-" + segmentName,""),
                                "ImageId": regionObject.AMIs.Centos.NAT,
                                "InstanceType": processorProfile.Processor,
                                "SecurityGroups" : (sshEnabled && !sshStandalone)?then(
                                                        [
                                                            { "Ref": sshToProxySecurityGroupId },
                                                            { "Ref": allToNATSecurityGroupId }
                                                        ],
                                                        [
                                                            { "Ref": allToNATSecurityGroupId }
                                                        ]
                                                    ),
                                "IamInstanceProfile" : { "Ref" : instanceProfileId },
                                "AssociatePublicIpAddress": true,
                                "UserData": {
                                    "Fn::Base64": { 
                                        "Fn::Join": [ 
                                            "", 
                                            [
                                                "#!/bin/bash -ex\\n",
                                                "exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1\\n",
                                                "yum install -y aws-cfn-bootstrap\\n",
                                                "# Remainder of configuration via metadata\\n",
                                                "/opt/aws/bin/cfn-init -v",
                                                " --stack ", { "Ref" : "AWS::StackName" },
                                                " --resource " + asgId,
                                                " --region " + regionId + " --configsets nat\\n"
                                            ]
                                        ]
                                    }
                                }
                            }
                            outputs=[]
                        /]
                    [/#if]
                [/#list]
            [/#if]
        [/#if]

        [#switch segmentListMode]
            [#case "outputs"]
                [@outputValue formatId("domain", "segment", "domain") segmentDomain /]
                [@outputValue formatId("domain", "segment", "qualifier") segmentDomainQualifier /]
                [@outputValue formatId("domain", "segment", "certificate") segmentDomainCertificateId /]
                [#break]
    
        [/#switch]       
    [/#if]

    [#if deploymentSubsetRequired("dashboard")]
        [#assign dashboardWidgets = []]
        [#assign defaultTitleHeight = 1]
        [#assign defaultWidgetHeight = 3]
        [#assign defaultWidgetWidth = 3]
        [#assign dashboardY = 0]
        [#list dashboardComponents as dashboardComponent]
            [#assign dashboardWidgets += [{
                    "type" : "text",
                    "x" : 0,
                    "y" : dashboardY,
                    "width" : 24,
                    "height" : defaultTitleHeight,
                    "properties" : {
                        "markdown" : dashboardComponent.Title
                    }                    
                }]
            ]
            [#assign dashboardY += defaultTitleHeight]
            [#list dashboardComponent.Rows as row]
                [#assign dashboardX = 0]
                [#if row.Title?has_content]
                    [#assign dashboardWidgets += [{
                            "type" : "text",
                            "x" : dashboardX,
                            "y" : dashboardY,
                            "width" : defaultWidgetWidth,
                            "height" : defaultTitleHeight,
                            "properties" : {
                                "markdown" : row.Title
                            }                    
                        }]
                    ]
                    [#assign dashboardX += defaultWidgetWidth]
                [/#if]
                [#assign maxWidgetHeight = 0]
                [#list row.Widgets as widget]
                    [#assign widgetMetrics = []]
                    [#list widget.Metrics as widgetMetric]
                        [#assign widgetMetricObject =
                            [
                                widgetMetric.Namespace,
                                widgetMetric.Metric
                            ]
                        ]
                        [#if widgetMetric.Dimensions?has_content]
                            [#list widgetMetric.Dimensions as dimension]
                                [#assign widgetMetricObject +=
                                    [
                                        dimension.Name,
                                        dimension.Value
                                    ]
                                ]
                            [/#list]
                        [/#if]
                        [#assign renderingObject = {}]
                        [#if widgetMetric.Statistic?has_content]
                            [#assign renderingObject += 
                                {
                                    "stat" : widgetMetric.Statistic
                                }
                            ]
                        [/#if]
                        [#if widgetMetric.Period?has_content]
                            [#assign renderingObject += 
                                {
                                    "period" : widgetMetric.Period
                                }
                            ]
                        [/#if]
                        [#if widgetMetric.Label?has_content]
                            [#assign renderingObject += 
                                {
                                    "label" : widgetMetric.Period
                                }
                            ]
                        [/#if]
                        [#if renderingObject?has_content]
                            [#assign widgetMetricObject += [renderingObject]]
                        [/#if]
                        [#assign widgetMetrics += [widgetMetricObject]]
                    [/#list]
                    [#assign widgetWidth = widget.Width ! defaultWidgetWidth]
                    [#assign widgetHeight = widget.Height ! defaultWidgetHeight]
                    [#assign maxWidgetHeight = (widgetHeight > maxWidgetHeight)?then(
                                widgetHeight,
                                maxWidgetHeight)]
                    [#assign widgetProperties =
                        {
                            "metrics" : widgetMetrics,
                            "region" : region,
                            "stat" : "Sum",
                            "period": 300,
                            "view" : widget.asGraph?has_content?then(
                                            widget.asGraph?then(
                                                "timeSeries",
                                                "singleValue"),
                                            "singleValue"),
                            "stacked" : widget.stacked ! false
                        }                    
                    ]
                    [#if widget.Title?has_content]
                        [#assign widgetProperties +=
                            {
                                "title" : widget.Title
                            }
                        ]
                    [/#if]
                    [#assign dashboardWidgets +=
                        [
                            {
                                "type" : "metric",
                                "x" : dashboardX,
                                "y" : dashboardY,
                                "width" : widgetWidth,
                                "height" : widgetHeight,
                                "properties" : widgetProperties
                            }
                        ]
                    ]
                    [#assign dashboardX += widgetWidth]
                [/#list]
                [#assign dashboardY += maxWidgetHeight]
            [/#list]
        [/#list]
        [@createDashboard
            segmentListMode,
            dashboardId,
            formatSegmentFullName(),
            {
                "widgets" : dashboardWidgets
            } 
        /]
    [/#if]
[/#if]

