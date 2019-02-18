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

                       
        [#assign networkTier = getTier(tierId) ]
        [#assign networkLink = getLinkTarget(networkTier.Network.Link!{}) ]
        [#assign networkResources = networkLink.State.Resources ]
        [#assign vpcId = networkResources["vpc"].Id ]
        
        [#-- create Elastic IPs --]
        [#list gwResources["Zones"] as zoneResources ]
            [#if (zoneResources["eip"]!{})?has_content ]
                [#assign eipId = zoneResources["eip"].Id ]
                [#if deploymentSubsetRequired("eip", true) &&
                        isPartOfCurrentDeploymentUnit(eipId)]

                    [@createEIP
                        mode=listMode
                        id=eipId
                    /]

                [/#if]
        [/#list]

        [#switch gwSolution.Engine ]
            [#case "natgw"]
                [#list gwResources["Zones"] as zoneResources ]
                    [#assign natGatewayId = zoneResources["natGateway"].Id ]
                    [#assign natGatewayName = zoneResources["natGateway"].Name ]
                    [#assign eipId = zoneResources["eip"].Id]
                    [#assign subnetId = (networkResources.subnets[zone.Id])["subnet"].Id]

                    [#assign natGwTags = getCfTemplateCoreTags(
                                                natGatewayName,
                                                tier,
                                                component,
                                                "",
                                                true)]

                    [@createNATGateway
                        mode=listMode
                        id=natGatewayId
                        subnetId=subnetId
                        eipId=eipId
                        tags=natGwTags
                    /]

                [/#list]
            [#break]

            [#case "igw"]
                [#assign IGWId = zoneRouteTableResources["internetGateway"].Id ]
                [#assign IGWName = zoneRouteTableResources["internetGateway"].Name ]
                [#assign IGWAttachementId = zoneRouteTableResources["internetGatewayAttachement"].Id ]

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
            [#break]

            [#case "vpcendpoint"]
            [#break]

            [#case "instance"]

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
                    [#assign linkCount += 1 ]
                    [#if linkCount > 1 ]
                        [@cfException
                            mode=listMode
                            description="A port mapping can only have a maximum of one link"
                            context=subOccurrence
                        /]
                        [#continue]
                    [/#if]

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
                            [#assign routeTableIds += [linkTargetResources["routeTable"]]]
                    [/#switch]
                [/#if]
            [/#list]

            [#if core.Type == NETWORK_GATEWAY_DESTINATION_COMPONENT_TYPE]
                
                [#switch gwSolution.Engine ]
                    [#case "natgw" ]
                        [#break]
                    
                    [#case "igw" ]
                        [#break]
                    
                    [#case "vpcendpoint" ]
                        [#assign vpcEndpointResources = resources["vpcEndpoints"] ]

                        [#list vpcEndpointResources as zone, zoneVpcEndpoints ] 
                            [#assign subnet = networkResources["subnets"][tier][zone].Id ]
                            [@createVPCEndpoint
                                mode=listMode
                                id=formatVPCEndPointId(service)
                                vpcId=vpcId
                                service=service
                                type=zoneVpcEndpoints
                                routeTableIds=solutionRouteTables
                                subnetId=subnet
                            /]

                        [#break]

                    [#case "instance"]
                        [#break]

            [/#if]
        [/#list]
    [/#list]
[/#if]