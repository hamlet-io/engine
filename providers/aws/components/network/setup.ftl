[#ftl]
[#macro aws_network_cf_generationcontract_segment occurrence ]
    [@addDefaultGenerationContract subsets="template" /]
[/#macro]

[#macro aws_network_cf_setup_segment occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]

    [#local vpcId = resources["vpc"].Id]
    [#local vpcResourceId = resources["vpc"].ResourceId]
    [#local vpcName = resources["vpc"].Name]
    [#local vpcCIDR = resources["vpc"].Address]

    [#local dnsSupport = (network.DNSSupport)!solution.DNS.UseProvider ]
    [#local dnsHostnames = (network.DNSHostnames)!solution.DNS.GenerateHostNames ]

    [#if (resources["flowlogs"]!{})?has_content ]
        [#local flowLogsResources = resources["flowlogs"]]
        [#local flowLogsRoleId = flowLogsResources["flowLogRole"].Id ]
        [#local flowLogsAllId = flowLogsResources["flowLog"].Id ]
        [#local flowLogsAllLogGroupId = flowLogsResources["flowLogLg"].Id ]
        [#local flowLogsAllLogGroupName = flowLogsResources["flowLogLg"].Name ]

        [#if deploymentSubsetRequired("iam", true) &&
                isPartOfCurrentDeploymentUnit(flowLogsRoleId)]
            [@createRole
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
            [@createLogGroup
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
                id=flowLogsAllId
                vpcId=vpcResourceId
                roleId=flowLogsRoleId
                logGroupName=flowLogsAllLogGroupName
                trafficType="ALL"
            /]
        [/#if]

    [/#if]

    [#if deploymentSubsetRequired(NETWORK_COMPONENT_TYPE, true)]
        [@createVPC
            id=vpcId
            resourceId=vpcResourceId
            name=vpcName
            cidr=vpcCIDR
            dnsSupport=dnsSupport
            dnsHostnames=dnsHostnames
        /]
    [/#if]

    [#local legacyIGWId = "" ]
    [#if (resources["legacyIGW"]!{})?has_content]
        [#local legacyIGWId = resources["legacyIGW"].Id ]
        [#local legacyIGWResourceId = resources["legacyIGW"].ResourceId]
        [#local legacyIGWName = resources["legacyIGW"].Name]
        [#local legacyIGWAttachmentId = resources["legacyIGWAttachment"].Id ]

        [#if deploymentSubsetRequired(NETWORK_COMPONENT_TYPE, true)]
            [@createIGW
                id=legacyIGWId
                resourceId=legacyIGWResourceId
                name=legacyIGWName
            /]
            [@createIGWAttachment
                id=legacyIGWAttachmentId
                vpcId=vpcResourceId
                igwId=legacyIGWResourceId
            /]
        [/#if]
    [/#if]

    [#if (resources["subnets"]!{})?has_content ]

        [#local subnetResources = resources["subnets"]]

        [#list subnetResources as tierId, zoneSubnets  ]

            [#local networkTier = getTier(tierId) ]
            [#local tierNetwork = getTierNetwork(tierId) ]

            [#local networkLink = tierNetwork.Link!{} ]
            [#local routeTableId = tierNetwork.RouteTable!"" ]
            [#local networkACLId = tierNetwork.NetworkACL!"" ]

            [#if !networkLink?has_content || !routeTableId?has_content || !networkACLId?has_content ]
                [@fatal
                    message="Tier Network configuration incomplete"
                    context=
                        tierNetwork +
                        {
                            "Link" : networkLink,
                            "RouteTable" : routeTableId,
                            "NetworkACL" : networkACLId
                        }
                /]

            [#else]

                [#local routeTable = getLinkTarget(occurrence, networkLink + { "RouteTable" : routeTableId }, false )]
                [#local routeTableZones = routeTable.State.Resources["routeTables"] ]

                [#local networkACL = getLinkTarget(occurrence, networkLink + { "NetworkACL" : networkACLId }, false )]
                [#local networkACLId = networkACL.State.Resources["networkACL"].Id ]

                [#list zones as zone]

                    [#if zoneSubnets[zone.Id]?has_content]

                        [#local zoneSubnetResources = zoneSubnets[zone.Id]]
                        [#local subnetId = zoneSubnetResources["subnet"].Id ]
                        [#local subnetName = zoneSubnetResources["subnet"].Name ]
                        [#local subnetAddress = zoneSubnetResources["subnet"].Address ]
                        [#local routeTableAssociationId = zoneSubnetResources["routeTableAssoc"].Id]
                        [#local networkACLAssociationId = zoneSubnetResources["networkACLAssoc"].Id]
                        [#local routeTableId = (routeTableZones[zone.Id]["routeTable"]).Id]

                        [#if deploymentSubsetRequired(NETWORK_COMPONENT_TYPE, true)]
                            [@createSubnet
                                id=subnetId
                                name=subnetName
                                vpcId=vpcResourceId
                                tier=networkTier
                                zone=zone
                                cidr=subnetAddress
                                private=routeTable.Private!false
                            /]
                            [@createRouteTableAssociation
                                id=routeTableAssociationId
                                subnetId=subnetId
                                routeTableId=routeTableId
                            /]
                            [@createNetworkACLAssociation
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

        [@debug message="Suboccurrence" context=subOccurrence enabled=false /]

        [#local core = subOccurrence.Core ]
        [#local solution = subOccurrence.Configuration.Solution ]
        [#local resources = subOccurrence.State.Resources ]

        [#if !(solution.Enabled!false)]
            [#continue]
        [/#if]

        [#if core.Type == NETWORK_ROUTE_TABLE_COMPONENT_TYPE]

            [#local zoneRouteTables = resources["routeTables"] ]

            [#list zones as zone ]

                [#if zoneRouteTables[zone.Id]?has_content ]
                    [#local zoneRouteTableResources = zoneRouteTables[zone.Id] ]
                    [#local routeTableId = zoneRouteTableResources["routeTable"].Id]
                    [#local routeTableName = zoneRouteTableResources["routeTable"].Name]

                    [#if deploymentSubsetRequired(NETWORK_COMPONENT_TYPE, true)]
                        [@createRouteTable
                            id=routeTableId
                            name=routeTableName
                            vpcId=vpcResourceId
                            zone=zone
                        /]

                        [#if (zoneRouteTableResources["legacyIGWRoute"].Id!{})?has_content ]
                            [#local legacyIGWRouteId =  zoneRouteTableResources["legacyIGWRoute"].Id ]
                            [@createRoute
                                id=legacyIGWRouteId
                                routeTableId=routeTableId
                                route=
                                    {
                                        "Type" : "gateway",
                                        "IgwId" : legacyIGWResourceId,
                                        "CIDR" : "0.0.0.0/0"
                                    }
                            /]
                        [/#if]

                    [/#if]
                [/#if]
            [/#list]
        [/#if]

        [#if core.Type == NETWORK_ACL_COMPONENT_TYPE ]

            [#local networkACLId = resources["networkACL"].Id]
            [#local networkACLName = resources["networkACL"].Name]

            [#local networkACLRules = resources["rules"]]

            [#if deploymentSubsetRequired(NETWORK_COMPONENT_TYPE, true)]
                [@createNetworkACL
                    id=networkACLId
                    name=networkACLName
                    vpcId=vpcResourceId
                /]

                [#list networkACLRules as id, rule ]
                    [#local ruleId = rule.Id ]
                    [#local ruleConfig = solution.Rules[id] ]

                    [#if (ruleConfig.Source.IPAddressGroups)?seq_contains("_localnet")
                            && (ruleConfig.Source.IPAddressGroups)?size == 1 ]

                        [#local direction = "outbound" ]
                        [#local forwardIpAddresses = getGroupCIDRs(ruleConfig.Destination.IPAddressGroups, true, occurrence)]
                        [#local forwardPort = ports[ruleConfig.Destination.Port]]
                        [#local returnIpAddresses = getGroupCIDRs(ruleConfig.Destination.IPAddressGroups, true, occurrence)]
                        [#local returnPort = ports[ruleConfig.Source.Port]]

                    [#elseif (ruleConfig.Destination.IPAddressGroups)?seq_contains("_localnet")
                                && (ruleConfig.Source.IPAddressGroups)?size == 1 ]

                        [#local direction = "inbound" ]
                        [#local forwardIpAddresses = getGroupCIDRs(ruleConfig.Source.IPAddressGroups, true, occurrence)]
                        [#local forwardPort = ports[ruleConfig.Destination.Port]]
                        [#local returnIpAddresses = [ "0.0.0.0/0" ]]
                        [#local returnPort = ports[ruleConfig.Destination.Port]]

                    [#else]
                        [@fatal
                            message="Invalid network ACL either source or destination must be configured as _local to define direction"
                            context=port
                        /]
                    [/#if]

                    [#list forwardIpAddresses![] as ipAddress ]
                        [#local ruleOrder =  ruleConfig.Priority + ipAddress?index ]
                        [#local networkRule = {
                                "RuleNumber" : ruleOrder,
                                "Allow" : (ruleConfig.Action == "allow"),
                                "CIDRBlock" : ipAddress
                            }]
                        [@createNetworkACLEntry
                            id=formatId(ruleId,direction,ruleOrder)
                            networkACLId=networkACLId
                            outbound=(direction=="outbound")
                            rule=networkRule
                            port=forwardPort
                        /]
                    [/#list]

                    [#if ruleConfig.ReturnTraffic ]
                        [#local direction = (direction=="inbound")?then("outbound", "inbound")]

                        [#list returnIpAddresses![] as ipAddress ]
                            [#local ruleOrder = ruleConfig.Priority + ipAddress?index]

                            [#local networkRule = {
                                "RuleNumber" : ruleOrder,
                                "Allow" : (ruleConfig.Action == "allow"),
                                "CIDRBlock" : ipAddress
                                }]

                            [@createNetworkACLEntry
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
[/#macro]
