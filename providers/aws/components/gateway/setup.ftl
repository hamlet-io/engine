[#ftl]
[#macro aws_gateway_cf_segment occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#if deploymentSubsetRequired("genplan", false)]
        [@addDefaultGenerationPlan subsets="template" /]
        [#return]
    [/#if]

    [#local gwCore = occurrence.Core ]
    [#local gwSolution = occurrence.Configuration.Solution ]
    [#local gwResources = occurrence.State.Resources ]

    [#local tags = getOccurrenceCoreTags(occurrence, gwCore.FullName, "", true)]

    [#local occurrenceNetwork = getOccurrenceNetwork(occurrence) ]
    [#local networkLink = occurrenceNetwork.Link!{} ]

    [#if !networkLink?has_content ]
        [@cfException
            listMode
            "Tier Network configuration incomplete",
                {
                    "networkTier" : occurrenceNetwork,
                    "Link" : networkLink
                }
        /]

    [#else]

        [#local networkLinkTarget = getLinkTarget(occurrence, networkLink, false) ]
        [#if ! networkLinkTarget?has_content ]
            [@cfException listMode "Network could not be found" networkLink /]
            [#return]
        [/#if]

        [#local networkConfiguration = networkLinkTarget.Configuration.Solution]
        [#local networkResources = networkLinkTarget.State.Resources ]

        [#local legacyIGW = (networkResources["legacyIGW"]!{})?has_content]

        [#local vpcId = networkResources["vpc"].Id ]
        [#local vpcPrivateDNS = networkConfiguration.DNS.UseProvider && networkConfiguration.DNS.GenerateHostNames]

        [#local sourceIPAddressGroups = gwSolution.SourceIPAddressGroups ]
        [#local sourceCidrs = getGroupCIDRs(sourceIPAddressGroups, true, occurrence)]

        [#-- create Elastic IPs --]
        [#list gwResources["Zones"] as zone, zoneResources ]
            [#if (zoneResources["eip"]!{})?has_content ]
                [#local eipId = zoneResources["eip"].Id ]
                [#if deploymentSubsetRequired("eip", true) &&
                        isPartOfCurrentDeploymentUnit(eipId)]

                    [@createEIP
                        mode=listMode
                        id=eipId
                    /]

                [/#if]
            [/#if]
        [/#list]

        [#-- Gateway Creation --]
        [#switch gwSolution.Engine ]
            [#case "natgw"]
                [#list gwResources["Zones"] as zone, zoneResources ]
                    [#local natGatewayId = zoneResources["natGateway"].Id ]
                    [#local natGatewayName = zoneResources["natGateway"].Name ]
                    [#local eipId = zoneResources["eip"].Id]

                    [#local subnetId = (networkResources["subnets"][gwCore.Tier.Id][zone])["subnet"].Id]

                    [#local natGwTags = getOccurrenceCoreTags(
                                                occurrence,
                                                natGatewayName,
                                                "",
                                                false)]
                    [#if deploymentSubsetRequired(NETWORK_GATEWAY_COMPONENT_TYPE, true)]
                        [@createNATGateway
                            mode=listMode
                            id=natGatewayId
                            subnetId=subnetId
                            eipId=eipId
                            tags=natGwTags
                        /]
                    [/#if]

                [/#list]
            [#break]

            [#case "igw"]

                [#if !legacyIGW ]
                    [#local IGWId = gwResources["internetGateway"].Id ]
                    [#local IGWName = gwResources["internetGateway"].Name ]
                    [#local IGWAttachementId = gwResources["internetGatewayAttachement"].Id ]

                    [#if deploymentSubsetRequired(NETWORK_GATEWAY_COMPONENT_TYPE, true)]
                        [@createIGW
                            mode=listMode
                            id=IGWId
                            name=IGWName
                        /]
                        [@createIGWAttachment
                            mode=listMode
                            id=IGWAttachementId
                            vpcId=vpcId
                            igwId=IGWId
                        /]
                    [/#if]
                [/#if]
            [#break]

            [#case "vpcendpoint"]
            [#break]

        [/#switch]

        [#-- Security Group Creation --]

        [#local securityGroupId=""]
        [#local securityGroupName=""]

        [#switch gwSolution.Engine ]
            [#case "vpcendpoint" ]
                [#local securityGroupId = gwResources["sg"].Id]
                [#local securityGroupName = gwResources["sg"].Name ]

                [#if deploymentSubsetRequired(NETWORK_GATEWAY_COMPONENT_TYPE, true)]
                    [@createSecurityGroup
                        mode=listMode
                        id=securityGroupId
                        name=securityGroupName
                        occurrence=occurrence
                        vpcId=vpcId
                        /]

                    [#list sourceCidrs as cidr ]

                        [@createSecurityGroupIngress
                            mode=listMode
                            id=
                                formatDependentSecurityGroupIngressId(
                                    securityGroupId,
                                    replaceAlphaNumericOnly(cidr)
                                )
                            port=""
                            cidr=cidr
                            groupId=securityGroupId
                    /]
                    [/#list]
                [/#if]
                [#break]
        [/#switch]

        [#list occurrence.Occurrences![] as subOccurrence]

            [@debug message="Suboccurrence" context=subOccurrence enabled=false /]

            [#local core = subOccurrence.Core ]
            [#local solution = subOccurrence.Configuration.Solution ]
            [#local resources = subOccurrence.State.Resources ]

            [#-- Determine the IP whitelisting required --]
            [#local destinationIPAddressGroups = solution.IPAddressGroups ]
            [#local cidrs = getGroupCIDRs(destinationIPAddressGroups, true, subOccurrence)]

            [#local routeTableIds = []]

            [#list solution.Links?values as link]
                [#if link?is_hash]

                    [#local linkTarget = getLinkTarget(occurrence, link) ]

                    [@debug message="Link Target" context=linkTarget enabled=false /]

                    [#if !linkTarget?has_content]
                        [#continue]
                    [/#if]

                    [#local linkTargetCore = linkTarget.Core ]
                    [#local linkTargetConfiguration = linkTarget.Configuration ]
                    [#local linkTargetResources = linkTarget.State.Resources ]
                    [#local linkTargetAttributes = linkTarget.State.Attributes ]

                    [#switch linkTargetCore.Type]

                        [#case NETWORK_ROUTE_TABLE_COMPONENT_TYPE]

                            [#local publicRouteTable = linkTargetConfiguration.Solution.Public ]

                            [#list linkTargetResources["routeTables"] as zone, zoneRouteTableResources ]

                                [#local zoneRouteTableId = zoneRouteTableResources["routeTable"].Id]
                                [#local routeTableIds += [ zoneRouteTableId ]]

                                    [#if deploymentSubsetRequired(NETWORK_GATEWAY_COMPONENT_TYPE, true)]

                                    [#switch gwSolution.Engine ]
                                        [#case "natgw" ]
                                            [#local zoneResources = gwResources["Zones"]]
                                            [#if multiAZ ]
                                                [#local natGatewayId = (zoneResources[zone]["natGateway"]).Id]
                                            [#else]
                                                [#local natGatewayId = (zoneResources[(zones[0].Id)]["natGateway"]).Id]
                                            [/#if]
                                            [#list cidrs as cidr ]
                                                [@createRoute
                                                    mode=listMode
                                                    id=formatRouteId(zoneRouteTableId, core.Id, cidr?index)
                                                    routeTableId=zoneRouteTableId
                                                    route=
                                                        {
                                                            "Type" : "nat",
                                                            "NatId" : natGatewayId,
                                                            "CIDR" : cidr
                                                        }
                                                /]
                                            [/#list]
                                            [#break]

                                        [#case "igw"]

                                            [#if !legacyIGW ]
                                                [#if publicRouteTable ]
                                                    [#list cidrs as cidr ]
                                                        [@createRoute
                                                            mode=listMode
                                                            id=formatRouteId(zoneRouteTableId, core.Id, cidr?index)
                                                            routeTableId=zoneRouteTableId
                                                            route=
                                                                {
                                                                    "Type" : "gateway",
                                                                    "IgwId" : IGWId,
                                                                    "CIDR" : cidr
                                                                }
                                                            dependencies=IGWAttachementId
                                                        /]
                                                    [/#list]
                                                [#else]
                                                    [@cfException
                                                        mode=listMode
                                                        description="Cannot add internet gateway to private route table. Route table must be public"
                                                        context={ "Gateway" : subOccurrence, "RouteTable" :  link }
                                                    /]
                                                [/#if]
                                            [/#if]
                                            [#break]
                                        [/#switch]
                                    [/#if]
                                [/#list]
                            [#break]

                    [/#switch]
                [/#if]
            [/#list]

            [#switch gwSolution.Engine ]
                [#case "vpcendpoint" ]
                    [#local vpcEndpointResources = resources["vpcEndpoints"]!{} ]
                    [#if deploymentSubsetRequired(NETWORK_GATEWAY_COMPONENT_TYPE, true)]

                        [#list vpcEndpointResources as resourceId, zoneVpcEndpoint ]
                            [#local endpointSubnets = [] ]
                            [#list networkResources["subnets"][gwCore.Tier.Id] as zone,resources]
                                [#if zoneVpcEndpoint.EndpointZones?seq_contains(zone )]
                                    [#local endpointSubnets += [ resources["subnet"].Id ] ]
                                [/#if]
                            [/#list]
                            [@createVPCEndpoint
                                mode=listMode
                                id=zoneVpcEndpoint.Id
                                vpcId=vpcId
                                service=zoneVpcEndpoint.ServiceName
                                type=zoneVpcEndpoint.EndpointType
                                routeTableIds=routeTableIds
                                subnetIds=endpointSubnets
                                privateDNSZone=vpcPrivateDNS
                                securityGroupIds=securityGroupId
                            /]
                        [/#list]
                    [/#if]
                    [#break]
            [/#switch]
        [/#list]
    [/#if]
[/#macro]