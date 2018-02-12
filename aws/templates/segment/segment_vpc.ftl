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
            mode=segmentListMode
            id=flowLogsRoleId                               
            trustedServices=["vpc-flow-logs.amazonaws.com"]
            policies=
                [
                    getPolicyDocument(
                        getCloudWatchLogsProduceStatement(),
                        formatName("vpcflowlogs"))
                ]
        /]        
    [/#if]

    [#if deploymentSubsetRequired("flowlogs", true) &&
            isPartOfCurrentDeploymentUnit(flowLogsAllLogGroupId)]
        [@createVPCLogGroup
            mode=segmentListMode
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
                mode=segmentListMode
                id=flowLogsAllId
                vpcId=vpcId
                roleId=flowLogsRoleId
                logGroupName=flowLogsAllLogGroupName
                trafficType="ALL"
            /]
        [/#if]
            
        [@createSegmentSNSTopic
            mode=segmentListMode
            id=topicId
        /]

        [@createVPC 
            mode=segmentListMode
            id=vpcId
            name=formatVPCName()
            cidr=segmentObject.CIDR.Address + "/" + segmentObject.CIDR.Mask
            dnsSupport=dnsSupport
            dnsHostnames=dnsHostnames
        /]

        [#if internetAccess]
            [@createIGW
                mode=segmentListMode
                id=igwId
                name=formatIGWName()
            /]
            [@createIGWAttachment
                mode=segmentListMode
                id=formatId("igw","attachment")
                vpcId=vpcId
                igwId=igwId
            /]
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
                        mode=segmentListMode
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
                                            mode=segmentListMode
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
                mode=segmentListMode
                id=formatVPCEndPointId(service)
                vpcId=vpcId
                service=service
                routeTableIds=solutionRouteTables
            /]
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
                    mode=segmentListMode
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
                                    mode=segmentListMode
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
                    mode=segmentListMode
                    id=subnetId
                    name=subnetName
                    vpcId=vpcId
                    tier=tier
                    zone=zone
                    cidr=baseAddress[0] + "." + baseAddress[1] + "." + (subnetAddress/256)?int + "." + subnetAddress%256 + "/" + subnetMask
                    private=routeTable.Private!false
                /]
                [@createRouteTableAssociation
                    mode=segmentListMode
                    id=routeTableAssociationId
                    subnetId=subnetId
                    routeTableId=routeTableId
                /]
                [@createNetworkACLAssociation
                    mode=segmentListMode
                    id=networkACLAssociationId
                    subnetId=subnetId
                    networkACLId=networkACLId
                /]
            [/#list]
        [/#list]

        [@cfTemplateOutput
            mode=segmentListMode
            id=formatId("domain", "segment", "domain")
            value=segmentDomain
        /]
        [@cfTemplateOutput
            mode=segmentListMode
            id=formatId("domain", "segment", "qualifier")
            value=segmentDomainQualifier
        /]
        [@cfTemplateOutput
            mode=segmentListMode
            id=formatId("domain", "segment", "certificate")
            value=segmentDomainCertificateId
        /]
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
            mode=segmentListMode
            id=dashboardId
            name=formatSegmentFullName()
            body=
                {
                    "widgets" : dashboardWidgets
                } 
        /]
    [/#if]
[/#if]

[#-- SSH --]

[#assign sshFromProxySecurityGroupId = formatSSHFromProxySecurityGroupId()]
[#assign sshInVpc = getExistingReference(sshFromProxySecurityGroupId, "", "", "vpc")?has_content ]
[#assign sshComponent =
    sshInVpc?then(
        {
            "Id" : "ssh",
            "Name" : "ssh"
        },
        component
    )
]
[#assign sshToProxySecurityGroupId = formatComponentSecurityGroupId(tier, sshComponent)]

[#if sshEnabled &&
    (
        (componentType == "ssh") || 
        ((componentType == "vpc") && sshInVpc)
    )]

    [#assign roleId = formatComponentRoleId(tier, sshComponent)]

    [#if deploymentSubsetRequired("iam", true) &&
            isPartOfCurrentDeploymentUnit(roleId) &&
            sshStandalone]
        [@createRole
            mode=segmentListMode
            id=roleId
            trustedServices=["ec2.amazonaws.com" ]
            policies=
                [
                    getPolicyDocument(
                        getIPAddressUpdateStatement() +
                            getS3ListStatement(codeBucket) +
                            getS3ReadStatement(codeBucket),
                        formatName(tier, sshComponent))
                ]
        /]
    [/#if]

    [#assign eipId = formatComponentEIPId(tier, sshComponent)]
    
    [#if deploymentSubsetRequired("eip", true) &&
            isPartOfCurrentDeploymentUnit(eipId) &&
            sshStandalone]
        [@createEIP
            mode=segmentListMode
            id=eipId
        /]
    [/#if]

    [#if deploymentSubsetRequired("ssh", true)]
        [@createSecurityGroup
            mode=segmentListMode
            tier=tier
            component=sshComponent
            id=sshToProxySecurityGroupId
            name=formatName(productName, segmentName, tier, sshComponent)
            description="Security Group for inbound SSH to the SSH Proxy"
            ingressRules=
                [
                    {
                        "Port" : "ssh",
                        "CIDR" : 
                            (sshActive || sshStandalone)?then(
                                getUsageCIDRs(
                                    "ssh",
                                    (segmentObject.SSH.IPAddressGroups)!
                                        segmentObject.IPAddressGroups![]),
                                []
                            )
                    }
                ]
        /]
    
        [@createSecurityGroup
            mode=segmentListMode
            tier="all"
            component=sshComponent
            id=sshFromProxySecurityGroupId
            name=formatName(productName, segmentName, "all", sshComponent)
            description="Security Group for SSH access from the SSH Proxy"
            ingressRules=
                [
                    {
                        "Port" : "ssh",
                        "CIDR" : [sshToProxySecurityGroupId]
                    }
                ]
        /]
        
        [#if sshStandalone]
            [#assign instanceProfileId = formatEC2InstanceProfileId(tier, sshComponent)]

            [@cfTemplate
                mode=segmentListMode
                id=instanceProfileId
                type="AWS::IAM::InstanceProfile"
                properties=
                    {
                        "Path" : "/",
                        "Roles" : [ getReference(roleId) ]
                    }
                outputs={}
            /]
            
            [#assign asgId = formatEC2AutoScaleGroupId(tier, sshComponent)]
            [#assign launchConfigId = formatEC2LaunchConfigId(tier, sshComponent)]
    
            [@cfTemplate
                mode=segmentListMode
                id=asgId
                type="AWS::AutoScaling::AutoScalingGroup"
                dependencies=getLocalReferences(getSubnets(tier, false))
                metadata=
                    {
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
                                                    "echo \\\"cot:tier="          + tier.Id            + "\\\"\\n",
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
                                            "EIP_ALLOCID" :
                                                getReference(
                                                    eipId,
                                                    ALLOCATION_ATTRIBUTE_TYPE
                                                )
                                        },
                                        "ignoreErrors" : "false"
                                    }
                                }
                            }
                        }
                    }
                properties=
                    {
                        "Cooldown" : "30",
                        "LaunchConfigurationName": {"Ref": launchConfigId },
                        "MinSize": sshActive?then("1","0"),
                        "MaxSize": sshActive?then("1","0"),
                        "VPCZoneIdentifier": getSubnets(tier)
                    }
                tags=
                    getCfTemplateCoreTags(
                        formatComponentFullName(tier, sshComponent),
                        tier,
                        sshComponent,
                        "",
                        true)
            /]
        
            [#assign processorProfile = getProcessor(tier, sshComponent, "SSH")]
            [#assign updateCommand = "yum clean all && yum -y update"]
            [#if environmentId == "prod"]
                [#-- for production update only security packages --]
                [#assign updateCommand += " --security"]
            [/#if]
            [#-- daily cron record for updates --]
            [#assign dailyUpdateCron = 'echo \\"59 13 * * * ${updateCommand} >> /var/log/update.log 2>&1\\" >crontab.txt && crontab crontab.txt']
            [@cfTemplate
                mode=segmentListMode
                id=launchConfigId
                type="AWS::AutoScaling::LaunchConfiguration"
                properties=
                    {
                        "KeyName": productName + sshPerSegment?string("-" + segmentName,""),
                        "ImageId": regionObject.AMIs.Centos.EC2,
                        "InstanceType": processorProfile.Processor,
                        "SecurityGroups" : [ getReference(sshToProxySecurityGroupId) ],
                        "IamInstanceProfile" : getReference(instanceProfileId),
                        "AssociatePublicIpAddress": true,
                        "UserData":
                            {
                                "Fn::Base64": { 
                                    "Fn::Join": [ 
                                        "", 
                                        [
                                            "#!/bin/bash -ex\\n",
                                            "exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1\\n",
                                            updateCommand, "\\n",
                                            dailyUpdateCron, "\\n",
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
                outputs={}
            /]
        [/#if]
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
            mode=segmentListMode
            id=roleId
            trustedServices=["ec2.amazonaws.com" ]
            policies=
                [
                    getPolicyDocument(
                        getIPAddressUpdateStatement() +
                            getSubnetReadStatement() +
                            getRouteAllStatement() +
                            getInstanceUpdateStatement() +
                            getS3ListStatement(codeBucket) +
                            getS3ReadStatement(codeBucket),
                        formatName(tier, natComponent))
                ]
        /]
    [/#if]

    [#if deploymentSubsetRequired("eip", true)]
        [#list zones as zone]
            [#if natPerAZ || zone?is_first]
                [#assign eipId = formatComponentEIPId(tier, natComponent, zone)]
                [#if isPartOfCurrentDeploymentUnit(eipId)]
                    [@createEIP
                        mode=segmentListMode
                        id=eipId
                    /]
                [/#if]
            [/#if]
        [/#list]
    [/#if]

    [#if deploymentSubsetRequired("nat", true)]
        [#if !natHosted]
            [#assign instanceProfileId = formatEC2InstanceProfileId(tier, natComponent)]
    
            [@cfTemplate
                mode=segmentListMode
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
                mode=segmentListMode
                tier=tier
                component=natComponent
                id=allToNATSecurityGroupId
                name=formatName(productName, segmentName, tier, natComponent)
                description="Security Group for outbound traffic to the NAT"
                ingressRules=
                    [
                        {
                            "Port" : "all",
                            "CIDR" : [segmentObject.CIDR.Address + "/" + segmentObject.CIDR.Mask]
                        }
                    ]
            /]
        [/#if]
        [#list zones as zone]
            [#if natPerAZ || zone?is_first]
                [#assign eipId = formatComponentEIPId(tier, natComponent, zone)]
                [#if natHosted]
                    [#assign natGatewayId = formatNATGatewayId(tier, zone)]
                    [@createNATGateway
                        mode=segmentListMode
                        id=natGatewayId
                        subnetId=formatSubnetId(tier, zone)
                        eipId=eipId
                    /]
                    [#assign updatedRouteTables = []]
                    [#list tiers as tier]
                        [#assign routeTable = routeTables[tier.RouteTable]]
                        [#if routeTable.Private!false]
                            [#assign routeTableId = formatRouteTableId(routeTable,natPerAZ?string(zone.Id,""))]
                            [#if !updatedRouteTables?seq_contains(routeTableId)]
                                [#assign updatedRouteTables += [routeTableId]]
                                [@createRoute
                                    mode=segmentListMode
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
    
                    [@cfTemplate
                        mode=segmentListMode
                        id=asgId
                        type="AWS::AutoScaling::AutoScalingGroup"
                        dependencies=getLocalReferences(formatSubnetId(tier, zone))
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
                                                            "echo \\\"cot:tier="          + tier.Id            + "\\\"\\n",
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
                    [#if environmentId == "prod"]
                        [#-- for production update only security packages --]
                        [#assign updateCommand += " --security"]
                    [/#if]
                    [#-- daily cron record for updates --]
                    [#assign dailyUpdateCron = 'echo \\"59 13 * * * ${updateCommand} >> /var/log/update.log 2>&1\\" >crontab.txt && crontab crontab.txt']
                    [@cfTemplate
                        mode=segmentListMode
                        id=launchConfigId
                        type="AWS::AutoScaling::LaunchConfiguration"
                        properties=
                            {
                                "KeyName": productName + sshPerSegment?string("-" + segmentName,""),
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
                                                "#!/bin/bash -ex\\n",
                                                "exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1\\n",
                                                updateCommand, "\\n",
                                                dailyUpdateCron, "\\n",
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
                        outputs={}
                    /]
                [/#if]
            [/#if]
        [/#list]
    [/#if]
[/#if]



