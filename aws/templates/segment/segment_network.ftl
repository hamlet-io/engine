[#if componentType == NETWORK_COMPONENT_TYPE ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]

        [#assign vpcId = resources["vpc"].Id]
        [#assign vpcResourceId = resources["vpc"].ResourceId]
        [#assign vpcName = resources["vpc"].Name]
        [#assign vpcCIDR = resources["vpc"].Address]

        [#assign dnsSupport = (network.DNSSupport)!solution.DNS.UseProvider ]
        [#assign dnsHostnames = (network.DNSHostnames)!solution.DNS.GenerateHostNames ]

        [#if (resources["flowlogs"]!{})?has_content ]
            [#assign flowLogsResources = resources["flowlogs"]]
            [#assign flowLogsRoleId = flowLogsResources["flowLogRole"].Id ]
            [#assign flowLogsAllId = flowLogsResources["flowLog"].Id ]
            [#assign flowLogsAllLogGroupId = flowLogsResources["flowLogLg"].Id ]
            [#assign flowLogsAllLogGroupName = flowLogsResources["flowLogLg"].Name ]

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
                                formatName(AWS_VPC_FLOWLOG_RESOURCE_TYPE))
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

            [#if deploymentSubsetRequired(NETWORK_COMPONENT_TYPE, true)]
                [@createVPCFlowLog
                    mode=listMode
                    id=flowLogsAllId
                    vpcId=vpcResourceId
                    roleId=flowLogsRoleId
                    logGroupName=flowLogsAllLogGroupName
                    trafficType="ALL"
                /]
            [/#if]

        [/#if]

        [#if (resources["legacySnsTopic"]!{})?has_content ]
            [#assign topicId = resources["legacySnsTopic"].Id ]
            [#if deploymentSubsetRequired(NETWORK_COMPONENT_TYPE, true)]
                [@createSegmentSNSTopic
                    mode=listMode
                    id=topicId
                /]
            [/#if]
        [/#if]

        [#if deploymentSubsetRequired(NETWORK_COMPONENT_TYPE, true)]
            [@createVPC
                mode=listMode
                id=vpcId
                resourceId=vpcResourceId
                name=vpcName
                cidr=vpcCIDR
                dnsSupport=dnsSupport
                dnsHostnames=dnsHostnames
            /]
        [/#if]

        [#assign legacyIGWId = "" ]
        [#if (resources["legacyIGW"]!{})?has_content]
            [#assign legacyIGWId = resources["legacyIGW"].Id ]
            [#assign legacyIGWResourceId = resources["legacyIGW"].ResourceId]
            [#assign legacyIGWName = resources["legacyIGW"].Name]
            [#assign legacyIGWAttachmentId = resources["legacyIGWAttachment"].Id ]

            [#if deploymentSubsetRequired(NETWORK_COMPONENT_TYPE, true)]
                [@createIGW
                    mode=listMode
                    id=legacyIGWId
                    resourceId=legacyIGWResourceId
                    name=legacyIGWName
                /]
                [@createIGWAttachment
                    mode=listMode
                    id=legacyIGWAttachmentId
                    vpcId=vpcResourceId
                    igwId=legacyIGWResourceId
                /]
            [/#if]
        [/#if]

        [#if (resources["subnets"]!{})?has_content ]

            [#assign subnetResources = resources["subnets"]]

            [#list subnetResources as tierId, zoneSubnets  ]

                [#assign networkTier = getTier(tierId) ]

                [#assign networkLink = networkTier.Network.Link!{} ]
                [#assign routeTableId = networkTier.Network.RouteTable!"" ]
                [#assign networkACLId = networkTier.Network.NetworkACL!"" ]

                [#if !networkLink?has_content || !routeTableId?has_content || !networkACLId?has_content ]
                    [@cfException
                        listMode
                        "Tier Network configuration incomplete",
                        networkTier.Network +
                            {
                                "Link" : networkLink,
                                "RouteTable" : routeTableId,
                                "NetworkACL" : networkACLId
                            }
                    /]

                [#else]

                    [#assign routeTable = getLinkTarget(occurrence, networkLink + { "RouteTable" : routeTableId }, false )]
                    [#assign routeTableZones = routeTable.State.Resources["routeTables"] ]

                    [#assign networkACL = getLinkTarget(occurrence, networkLink + { "NetworkACL" : networkACLId }, false )]
                    [#assign networkACLId = networkACL.State.Resources["networkACL"].Id ]

                    [#list zones as zone]

                        [#if zoneSubnets[zone.Id]?has_content]

                            [#assign zoneSubnetResources = zoneSubnets[zone.Id]]
                            [#assign subnetId = zoneSubnetResources["subnet"].Id ]
                            [#assign subnetName = zoneSubnetResources["subnet"].Name ]
                            [#assign subnetAddress = zoneSubnetResources["subnet"].Address ]
                            [#assign routeTableAssociationId = zoneSubnetResources["routeTableAssoc"].Id]
                            [#assign networkACLAssociationId = zoneSubnetResources["networkACLAssoc"].Id]
                            [#assign routeTableId = (routeTableZones[zone.Id]["routeTable"]).Id]

                            [#if deploymentSubsetRequired(NETWORK_COMPONENT_TYPE, true)]
                                [@createSubnet
                                    mode=listMode
                                    id=subnetId
                                    name=subnetName
                                    vpcId=vpcResourceId
                                    tier=networkTier
                                    zone=zone
                                    cidr=subnetAddress
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
                            [/#if]
                        [/#if]
                    [/#list]
                [/#if]
            [/#list]
        [/#if]

        [#list occurrence.Occurrences![] as subOccurrence]

            [#assign core = subOccurrence.Core ]
            [#assign solution = subOccurrence.Configuration.Solution ]
            [#assign resources = subOccurrence.State.Resources ]

            [@cfDebug listMode subOccurrence false /]

            [#if core.Type == NETWORK_ROUTE_TABLE_COMPONENT_TYPE]

                [#assign zoneRouteTables = resources["routeTables"] ]

                [#list zones as zone ]

                    [#if zoneRouteTables[zone.Id]?has_content ]
                        [#assign zoneRouteTableResources = zoneRouteTables[zone.Id] ]
                        [#assign routeTableId = zoneRouteTableResources["routeTable"].Id]
                        [#assign routeTableName = zoneRouteTableResources["routeTable"].Name]

                        [#if deploymentSubsetRequired(NETWORK_COMPONENT_TYPE, true)]
                            [@createRouteTable
                                mode=listMode
                                id=routeTableId
                                name=routeTableName
                                vpcId=vpcResourceId
                                zone=zone
                            /]

                            [#if (zoneRouteTableResources["legacyIGWRoute"].Id!{})?has_content ]
                                [#assign legacyIGWRouteId =  zoneRouteTableResources["legacyIGWRoute"].Id ]
                                [@createRoute
                                    mode=listMode
                                    id=legacyIGWRouteId
                                    routeTableId=routeTableId
                                    route=
                                        {
                                            "Type" : "gateway",
                                            "IgwId" : legacyIGWId,
                                            "CIDR" : "0.0.0.0/0"
                                        }
                                /]
                            [/#if]

                        [/#if]
                    [/#if]
                [/#list]
            [/#if]

            [#if core.Type == NETWORK_ACL_COMPONENT_TYPE ]

                [#assign networkACLId = resources["networkACL"].Id]
                [#assign networkACLName = resources["networkACL"].Name]

                [#assign networkACLRules = resources["rules"]]

                [#if deploymentSubsetRequired(NETWORK_COMPONENT_TYPE, true)]
                    [@createNetworkACL
                        mode=listMode
                        id=networkACLId
                        name=networkACLName
                        vpcId=vpcResourceId
                    /]

                    [#list networkACLRules as id, rule ]
                        [#assign ruleId = rule.Id ]
                        [#assign ruleConfig = solution.Rules[id] ]

                        [#if (ruleConfig.Source.IPAddressGroups)?seq_contains("_localnet")
                                && (ruleConfig.Source.IPAddressGroups)?size == 1 ]

                            [#assign direction = "outbound" ]
                            [#assign forwardIpAddresses = getGroupCIDRs(ruleConfig.Destination.IPAddressGroups, true, occurrence)]
                            [#assign forwardPort = ports[ruleConfig.Destination.Port]]
                            [#assign returnIpAddresses = getGroupCIDRs(ruleConfig.Destination.IPAddressGroups, true, occurrence)]
                            [#assign returnPort = ports[ruleConfig.Source.Port]]

                        [#elseif (ruleConfig.Destination.IPAddressGroups)?seq_contains("_localnet")
                                    && (ruleConfig.Source.IPAddressGroups)?size == 1 ]

                            [#assign direction = "inbound" ]
                            [#assign forwardIpAddresses = getGroupCIDRs(ruleConfig.Source.IPAddressGroups, true, occurrence)]
                            [#assign forwardPort = ports[ruleConfig.Destination.Port]]
                            [#assign returnIpAddresses = [ "0.0.0.0/0" ]]
                            [#assign returnPort = ports[ruleConfig.Destination.Port]]

                        [#else]
                            [@cfException listMode "Invalid network ACL either source or destination must be configured as _local to define direction" port /]
                        [/#if]

                        [#list forwardIpAddresses![] as ipAddress ]
                            [#assign ruleOrder =  ruleConfig.Priority + ipAddress?index ]
                            [#assign networkRule = {
                                    "RuleNumber" : ruleOrder,
                                    "Allow" : (ruleConfig.Action == "allow"),
                                    "CIDRBlock" : ipAddress
                                }]
                            [@createNetworkACLEntry
                                mode=listMode
                                id=formatId(ruleId,direction,ruleOrder)
                                networkACLId=networkACLId
                                outbound=(direction=="outbound")
                                rule=networkRule
                                port=forwardPort
                            /]
                        [/#list]

                        [#if ruleConfig.ReturnTraffic ]
                            [#assign direction = (direction=="inbound")?then("outbound", "inbound")]

                            [#list returnIpAddresses![] as ipAddress ]
                                [#assign ruleOrder = ruleConfig.Priority + ipAddress?index]

                                [#assign networkRule = {
                                    "RuleNumber" : ruleOrder,
                                    "Allow" : (ruleConfig.Action == "allow"),
                                    "CIDRBlock" : ipAddress
                                    }]

                                [@createNetworkACLEntry
                                    mode=listMode
                                    id=formatId(ruleId,direction,ruleOrder)
                                    networkACLId=networkACLId
                                    outbound=(direction=="outbound")
                                    rule=networkRule
                                    port=returnPort
                                /]
                            [/#list]
                        [/#if]
                    [/#list]
                [/#if]
            [/#if]
        [/#list]
    [/#list]
[/#if]