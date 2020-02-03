[#ftl]

[#-- Resources --]

[#macro aws_network_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#if legacyVpc ]
        [#local vpcId = formatVPCTemplateId() ]
        [#local vpcName = formatVPCName()]
        [#local legacyIGWId = formatVPCIGWTemplateId() ]
        [#local legacyIGWName = formatIGWName() ]
        [#local legacyIGWAttachmentId = formatId(AWS_VPC_IGW_ATTACHMENT_TYPE) ]
    [#else]
        [#local vpcId = formatResourceId(AWS_VPC_RESOURCE_TYPE, core.Id)]
        [#local vpcName = core.FullName ]
    [/#if]

    [#local vpcFlowLogEnabled = environmentObject.Operations.FlowLogs.Enabled!
                                    segmentObject.Operations.FlowLogs.Enabled!
                                    solution.Logging.EnableFlowLogs ]

    [#local networkCIDR = (network.CIDR)?has_content?then(
                    network.CIDR.Address + "/" + network.CIDR.Mask,
                    solution.Address.CIDR )]

    [#local subnetCIDRMask = getSubnetMaskFromSizes(
                                networkCIDR,
                                network.Tiers.Order?size,
                                network.Zones.Order?size )]
    [#local subnetCIDRS = getSubnetsFromNetwork(networkCIDR, subnetCIDRMask)]

    [#local flowLogLgName = legacyVpc?then(
                                formatSegmentLogGroupName(AWS_VPC_FLOWLOG_RESOURCE_TYPE, "all")
                                formatAbsolutePath(core.FullAbsolutePath, "all" ) )]
    [#local flowLogId = legacyVpc?then(
                                formatVPCFlowLogsId("all"),
                                formatDependentResourceId(AWS_VPC_FLOWLOG_RESOURCE_TYPE, vpcId, "all" ))]

    [#local subnets = {} ]
    [#-- Define subnets --]
    [#list segmentObject.Network.Tiers.Order as tierId]
        [#local networkTier = getTier(tierId) ]
        [#if ! (networkTier?has_content && networkTier.Network.Enabled &&
                    networkTier.Network.Link.Tier == core.Tier.Id && networkTier.Network.Link.Component == core.Component.Id &&
                    (networkTier.Network.Link.Version!core.Version.Id) == core.Version.Id && (networkTier.Network.Link.Instance!core.Instance.Id) == core.Instance.Id  ) ]
            [#continue]
        [/#if]
        [#list zones as zone]
            [#local subnetId = legacyVpc?then(
                                    formatSubnetId(networkTier, zone),
                                    formatResourceId(AWS_VPC_SUBNET_RESOURCE_TYPE, core.Id, networkTier.Id, zone.Id))]

            [#local subnetName = legacyVpc?then(
                                    formatSubnetName(networkTier, zone),
                                    formatName(core.FullName, networkTier.Name, zone.Name))]

            [#local subnetIndex = ( tierId?index * network.Zones.Order?size ) + zone?index]
            [#local subnetCIDR = subnetCIDRS[subnetIndex]]
            [#local subnets =  mergeObjects( subnets, {
                networkTier.Id  : {
                    zone.Id : {
                        "subnet" : {
                            "Id" : subnetId,
                            "Name" : subnetName,
                            "Address" : subnetCIDR,
                            "Type" : AWS_VPC_SUBNET_TYPE
                        },
                        "routeTableAssoc" : {
                            "Id" : formatRouteTableAssociationId(subnetId),
                            "Type" : AWS_VPC_NETWORK_ROUTE_TABLE_ASSOCIATION_TYPE
                        },
                        "networkACLAssoc" : {
                            "Id" : formatNetworkACLAssociationId(subnetId),
                            "Type" : AWS_VPC_NETWORK_ACL_ASSOCIATION_TYPE
                        }
                    }
                }
            })]
        [/#list]
    [/#list]

    [#assign componentState =
        {
            "Resources" : {
                "vpc" : {
                    "Id" : legacyVpc?then(formatVPCId(), vpcId),
                    "ResourceId" : vpcId,
                    "Name" : vpcName,
                    "Address": networkCIDR,
                    "Type" : AWS_VPC_RESOURCE_TYPE
                },
                "subnets" : subnets
            } +
            vpcFlowLogEnabled?then(
                { "flowlogs" : {
                    "flowLogRole" : {
                        "Id" : formatDependentRoleId(vpcId),
                        "Type" : AWS_IAM_ROLE_RESOURCE_TYPE,
                        "IncludeInDeploymentState" : false
                    },
                    "flowLogLg" : {
                        "Id" : formatDependentLogGroupId(vpcId, "all"),
                        "Name" : flowLogLgName,
                        "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                        "IncludeInDeploymentState" : false
                    },
                    "flowLog" : {
                        "Id" : flowLogId,
                        "Type" : AWS_VPC_FLOWLOG_RESOURCE_TYPE
                    }
                }},
                {}
            ) +
            legacyVpc?then(
                {
                    "legacyIGW" : {
                        "Id" : legacyVpc?then(formatVPCIGWId(), legacyIGWId),
                        "ResourceId" : legacyIGWId,
                        "Name" : legacyIGWName,
                        "Type" : AWS_VPC_IGW_RESOURCE_TYPE
                    },
                    "legacyIGWAttachment" : {
                        "Id" : legacyIGWAttachmentId,
                        "Type" : AWS_VPC_IGW_ATTACHMENT_TYPE
                    }
                },
                {}
            ),
            "Attributes" : {
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]

[#macro aws_networkroute_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local routeTables = {}]

    [#local routeTableId = formatResourceId(AWS_VPC_ROUTE_TABLE_RESOURCE_TYPE, core.Id)]
    [#local routeTableName = core.FullName ]

    [#if legacyVpc ]
        [#-- Support for IGW defined as part of VPC tempalte instead of Gateway --]
        [#local legacyIGWRouteId = formatRouteId(routeTableId, "gateway") ]
    [/#if]

    [#list segmentObject.Network.Tiers.Order as tierId]
        [#local networkTier = getTier(tierId) ]
        [#if ! (networkTier?has_content && networkTier.Network.Enabled ) ]
            [#continue]
        [/#if]

        [#list zones as zone]
            [#local zoneRouteTableId = formatId(routeTableId, zone.Id)]
            [#local zoneRouteTableName = formatName(routeTableName, zone.Id)]

            [#local routeTables = mergeObjects(routeTables, {
                    zone.Id : {
                        "routeTable" : {
                            "Id" : zoneRouteTableId,
                            "Name" : zoneRouteTableName,
                            "Type" : AWS_VPC_ROUTE_TABLE_RESOURCE_TYPE
                        }
                    } +
                    (legacyVpc && solution.Public )?then(
                        {
                            "legacyIGWRoute" : {
                                "Id" : formatId(legacyIGWRouteId, zone.Id),
                                "Type" : AWS_VPC_ROUTE_RESOURCE_TYPE
                            }
                        },
                        {}
                    )
            })]
        [/#list]
    [/#list]

    [#assign componentState =
        {
            "Resources" : {
                "routeTables" : routeTables
            },
            "Attributes" : {
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]

[#macro aws_networkacl_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#if legacyVpc ]
        [#local networkACLId = formatNetworkACLId(core.SubComponent.Id) ]
        [#local networkACLName = formatNetworkACLName(core.SubComponent.Name)]
    [#else]
        [#local networkACLId = formatNetworkACLId(core.Id) ]
        [#local networkACLName = formatNetworkACLName(core.Name)]
    [/#if]

    [#local networkACLRules = {}]
    [#list solution.Rules as id, rule]
        [#local networkACLRules += {
            rule.Id : {
                "Id" :  formatDependentResourceId(
                            AWS_VPC_NETWORK_ACL_RULE_RESOURCE_TYPE,
                            networkACLId,
                            rule.Id),
                "Type" : AWS_VPC_NETWORK_ACL_RULE_RESOURCE_TYPE
            }
        }]
    [/#list]

    [#assign componentState =
        {
            "Resources" : {
                "networkACL" : {
                    "Id" : networkACLId,
                    "Name" : networkACLName,
                    "Type" : AWS_VPC_NETWORK_ACL_RESOURCE_TYPE
                },
                "rules" : networkACLRules
            },
            "Attributes" : {
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]
