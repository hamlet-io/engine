[#if componentType == NETWORK_GATEWAY_COMPONENT_TYPE ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign gwCore = occurrence.Core ]
        [#assign gwSolution = occurrence.Configuration.Solution ]
        [#assign gwResources = occurrence.State.Resources ]

        [#assign tags = getCfTemplateCoreTags(
                        gwCore.FullName,
                        tier,
                        component,
                        "",
                        true)]

                            
        [#assign networkLink = tier.Network.Link!{} ]

        [#if !networkLink?has_content ]
            [@cfException 
                listMode 
                "Tier Network configuration incomplete",
                    {
                        "networkTier" : tier.Network,
                        "Link" : networkLink
                    }
            /]

        [#else]

            [#assign networkLinkTarget = getLinkTarget(occurrence, networkLink, false) ]
            [#if ! networkLinkTarget?has_content ]
                [@cfException listMode "Network could not be found" networkLink /]
                [#break]
            [/#if]

            [#assign networkConfiguration = networkLinkTarget.Configuration.Solution]
            [#assign networkResources = networkLinkTarget.State.Resources ]

            [#assign legacyIGW = (networkResources["legacyIGW"]!{})?has_content]
            
            [#assign vpcId = networkResources["vpc"].Id ]
            [#assign vpcPrivateDNS = networkConfiguration.DNS.UseProvider && networkConfiguration.DNS.GenerateHostNames]

            [#assign sourceIPAddressGroups = gwSolution.SourceIPAddressGroups ]
            [#assign sourceCidrs = getGroupCIDRs(sourceIPAddressGroups, true, occurrence)]

            [#-- create Elastic IPs --]
            [#list gwResources["Zones"] as zone, zoneResources ]
                [#if (zoneResources["eip"]!{})?has_content ]
                    [#assign eipId = zoneResources["eip"].Id ]
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
                        [#assign natGatewayId = zoneResources["natGateway"].Id ]
                        [#assign natGatewayName = zoneResources["natGateway"].Name ]
                        [#assign eipId = zoneResources["eip"].Id]

                        [#assign subnetId = (networkResources["subnets"][tier.Id][zone])["subnet"].Id]

                        [#assign natGwTags = getCfTemplateCoreTags(
                                                    natGatewayName,
                                                    tier,
                                                    component,
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
                        [#assign IGWId = gwResources["internetGateway"].Id ]
                        [#assign IGWName = gwResources["internetGateway"].Name ]
                        [#assign IGWAttachementId = gwResources["internetGatewayAttachement"].Id ]
                                        
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

            [#assign securityGroupId=""]
            [#assign securityGroupName=""]

            [#switch gwSolution.Engine ]
                [#case "vpcendpoint" ]
                    [#assign securityGroupId = gwResources["sg"].Id]
                    [#assign securityGroupName = gwResources["sg"].Name ]
                    
                    [#if deploymentSubsetRequired(NETWORK_GATEWAY_COMPONENT_TYPE, true)]
                        [@createSecurityGroup
                            mode=listMode
                            id=securityGroupId
                            name=securityGroupName
                            tier=tier
                            component=component
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

                [@cfDebug listMode subOccurrence false /]

                [#assign core = subOccurrence.Core ]
                [#assign solution = subOccurrence.Configuration.Solution ]
                [#assign resources = subOccurrence.State.Resources ]

                [#-- Determine the IP whitelisting required --]
                [#assign destinationIPAddressGroups = solution.IPAddressGroups ]
                [#assign cidrs = getGroupCIDRs(destinationIPAddressGroups)]

                [#assign routeTableIds = []]
                
                [#list solution.Links?values as link]
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

                            [#case NETWORK_ROUTE_TABLE_COMPONENT_TYPE]

                                [#assign publicRouteTable = linkTargetConfiguration.Solution.Public ]

                                [#list linkTargetResources["routeTables"] as zone, zoneRouteTableResources ]

                                    [#assign zoneRouteTableId = zoneRouteTableResources["routeTable"].Id]
                                    [#assign routeTableIds += [ zoneRouteTableId ]]

                                        [#if deploymentSubsetRequired(NETWORK_GATEWAY_COMPONENT_TYPE, true)]

                                        [#switch gwSolution.Engine ]
                                            [#case "natgw" ]
                                                [#assign zoneResources = gwResources["Zones"]]
                                                [#if multiAZ ]
                                                    [#assign natGatewayId = (zoneResources[zone]["natGateway"]).Id]
                                                [#else]
                                                    [#assign natGatewayId = (zoneResources[(zones[0].Id)]["natGateway"]).Id]
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
                        [#assign vpcEndpointResources = resources["vpcEndpoints"]!{} ]
                        [#if deploymentSubsetRequired(NETWORK_GATEWAY_COMPONENT_TYPE, true)]

                            [#list vpcEndpointResources as resourceId, zoneVpcEndpoint ] 
                                [#assign endpointSubnets = [] ]
                                [#list networkResources["subnets"][tier.Id] as zone,resources]
                                    [#if zoneVpcEndpoint.EndpointZones?seq_contains(zone )]
                                        [#assign endpointSubnets += [ resources["subnet"].Id ] ]
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
    [/#list]
[/#if]