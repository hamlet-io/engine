[#-- Components --]
[#assign NETWORK_COMPONENT_TYPE = "network" ]
[#assign NETWORK_ROUTE_TABLE_COMPONENT_TYPE = "networkroute"]
[#assign NETWORK_ACL_COMPONENT_TYPE = "networkacl"]
[#assign NETWORK_GATEWAY_COMPONENT_TYPE = "gateway"]
[#assign NETWORK_GATEWAY_DESTINATION_COMPONENT_TYPE = "gatewaydestination"]

[#assign componentConfiguration +=
    {
        NETWORK_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "A virtual network segment used by private resources"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "segment"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Active",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : ["Fragment", "Container"],
                    "Type" : STRING_TYPE,
                    "Default" : ""
                },
                { 
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration
                },
                {
                    "Names" : "Logging",
                    "Children" : [
                        {
                            "Names" : "EnableFlowLogs",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        }
                    ]
                },
                {
                    "Names" : "DNS",
                    "Children" : [
                        {
                            "Names" : "UseProvider",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "GenerateHostNames",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        }
                    ]
                },
                {
                    "Names" : "Address",
                    "Children" : [
                        {
                            "Names" : "CIDR",
                            "Type" : STRING_TYPE,
                            "Default" : "10.0.0.0/16"
                        }
                    ]
                }
            ],
            "Components" : [
                {
                    "Type" : NETWORK_ROUTE_TABLE_COMPONENT_TYPE,
                    "Component" : "RouteTables",
                    "Link" : "RouteTable"
                },
                {
                    "Type" : NETWORK_ACL_COMPONENT_TYPE,
                    "Component" : "NetworkACLs",
                    "Link" : "NetworkACL"
                }
            ]
        },
        NETWORK_ROUTE_TABLE_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "A network routing table providing acess to resources outside of the network"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "segment"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Active",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Public",
                    "Description" : "Does the route table require Public IP internet access",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "PerAZ",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false 
                },
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration
                }
            ]
        },
        NETWORK_ACL_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "A tier/subnet level network access control policy"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "segment"
                }
            ], 
            "Attributes" : [
                {
                    "Names" : "Active",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Rules",
                    "Subobjects" : true,
                    "Children" : [
                        {
                            "Names" : "Priority",
                            "Type" : NUMBER_TYPE,
                            "Required" : true
                        }
                        {
                            "Names" : "Action",
                            "Type" : STRING_TYPE,
                            "Default" : "deny",
                            "Values" : [ "allow", "deny" ]
                        },
                        {
                            "Names" : "Source",
                            "Description" : "Source of the network traffic",
                            "Children" : [
                                {
                                    "Names" : "IPAddressGroups",
                                    "Type" : ARRAY_OF_STRING_TYPE,
                                    "Required" : true
                                },
                                {
                                    "Names" : "Port",
                                    "Description" : "Port or port range the source is coming from",
                                    "Type" : STRING_TYPE,
                                    "Default" : "ephemeraltcp"
                                }
                            ]
                        },
                        {
                            "Names" : "Destination",
                            "Description" : "Destination of the network traffic",
                            "Children" : [
                                {
                                    "Names" : "IPAddressGroups",
                                    "Type" : ARRAY_OF_STRING_TYPE,
                                    "Required" : true
                                },
                                {
                                    "Names" : "Port",
                                    "Description" : "Port or port range the source is trying to access",
                                    "Type" : STRING_TYPE,
                                    "Required" : true
                                }
                            ]
                        },
                        {
                            "Names" : "ReturnTraffic",
                            "Description" : "If ACL is stateless add a return rule",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        }
                    ]
                }
            ]
        },
        NETWORK_GATEWAY_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "A service providing a route to another network"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "segment"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Active",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Engine",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Values" : [ "nat", "igw", "vpcendpoint" ]
                }
            ],
            "Components" : [
                {
                    "Type" : NETWORK_GATEWAY_DESTINATION_COMPONENT_TYPE,
                    "Component" : "Destinations",
                    "Link" : "Destination"
                }
            ]
        },
        NETWORK_GATEWAY_DESTINATION_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "A network destination offerred by the Gateway"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "segment"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Active",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "IPAddressGroups",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Services",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        }
    }]

[#function getNetworkState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local legacyVpc = false]
    [#local legacyVpcId = formatVPCTemplateId() ]

    [#if getExistingReference(legacyVpcId)?has_content ]
        [#local vpcId = formatVPCTemplateId() ]
        [#local legacyVpc = true ]
    [#else]
        [#local vpcId = formatResourceId(AWS_VPC_RESOURCE_TYPE, core.Id)]
    [/#if]
    

    [#assign vpcFlowLogEnabled = environmentObject.Operations.FlowLogs.Enabled!
                                segmentObject.Operations.FlowLogs.Enabled!
                                solution.Logging.EnableFlowLogs ]

    [#assign networkCIDR = (network.CIDR)?has_content?then(
                    network.CIDR.Address + "/" + network.CIDR.Mask,
                    solution.Address.CIDR
    )]

    [#assign networkAddress = networkCIDR?split("/")[0] ]
    [#assign networkMask = (networkCIDR?split("/")[1])?number ]
    [#assign baseAddress = networkAddress?split(".") ]

    [#assign addressOffset = baseAddress[2]?number*256 + baseAddress[3]?number]
    [#assign addressesPerTier = powersOf2[getPowerOf2(powersOf2[32 - networkMask]/(network.Tiers.Order?size))]]
    [#assign addressesPerZone = powersOf2[getPowerOf2(addressesPerTier / (network.Zones.Order?size))]]
    [#assign subnetMask = 32 - powersOf2?seq_index_of(addressesPerZone)]

    [#local subnets = {} ]
    [#-- Define subnets --]
    [#list segmentObject.Network.Tiers.Order as tierId]
        [#assign networkTier = getTier(tierId) ]
        [#if ! (networkTier?has_content && networkTier.Network.Enabled ) ]
            [#continue]
        [/#if]

        [#list zones as zone]
            [#assign subnetId = formatSubnetId(networkTier, zone)]
            [#assign subnetAddress = addressOffset + (networkTier.Network.Index * addressesPerTier) + (zone.Index * addressesPerZone) ]
            [#assign subnetCIDR = baseAddress[0] + "." + baseAddress[1] + "." + (subnetAddress/256)?int + "." + subnetAddress%256 + "/" + subnetMask]

            [#local subnets =  mergeObjects( subnets, {
                networkTier.Id  : {
                    zone.Id : {
                        "subnet" : {
                            "Id" : subnetId,
                            "Name" : formatSubnetName(networkTier, zone),
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

    [#local result =
        {
            "Resources" : {
                "vpc" : {
                    "Id" : vpcId,
                    "Name" : formatVPCName(),
                    "Address": networkAddress + "/" + networkMask,
                    "Type" : AWS_VPC_RESOURCE_TYPE
                },
                "subnets" : subnets
            } + 
            vpcFlowLogEnabled?then(
                { "flowlogs" : { 
                    "flowLogRole" : {
                        "Id" : formatDependentRoleId(vpcId),
                        "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                    },
                    "flowLogLg" : {
                        "Id" : formatDependentLogGroupId(vpcId, "all"),
                        "Name" : formatSegmentLogGroupName(AWS_VPC_FLOWLOG_RESOURCE_TYPE, "all"),
                        "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                    },
                    "flowLog" : {
                        "Id" : formatVPCFlowLogsId("all"),
                        "Type" : AWS_VPC_FLOWLOG_RESOURCE_TYPE
                    }
                }},
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
    [#return result ]
[/#function]

[#function getNetworkRouteTableState occurrence ]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#if solution.PerAZ ]
        [#local routeTableZones = zones ]
    [#else]
        [#local routeTableZones = [
                { 
                    "Id" : "regional"
                } 
            ]]
    [/#if]

    [#local zoneResources = {}]
    [#list routeTableZones as zone]
        [#local zoneResources += {
            zone.Id : {
                "routeTable" : {
                    "Id" : formatRouteTableId(core.Id,(solution.PerAZ)?string(zone.Id,"")),
                    "Name" : formatRouteTableName(core.Id,(solution.PerAZ)?string(zone.Id,"")),
                    "Type" : AWS_VPC_ROUTE_TABLE_RESOURCE_TYPE
                }
            }
        }]
    [/#list]

    [#return 
        {
            "Resources" : { 
                "routeTables" : zoneResources
            },
            "Attributes" : {
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]

[#function getNetworkACLState occurrence ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local networkACLId = formatNetworkACLId(core.Id) ]

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

    [#return 
        {
            "Resources" : { 
                "networkACL" : {
                    "Id" : formatNetworkACLId(core.Id),
                    "Name" : formatNetworkACLName(core.Name),
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
[/#function]

[#function getNetworkGatewayState occurrence ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]
    [#local engine = solution.Engine ]
    [#local resources = {} ]
    
    [#switch engine ]
        [#case "nat"] 
            [#list zones as zone]
                [#local resources += {
                    zone.Id : {
                        "natGateway" : {
                            "Id" : formatNATGatewayId(tier, zone),
                            "Name" : formatComponentFullName(tier, natComponent, zone),
                            "Type" : AWS_VPC_NAT_GATEWAY_RESOURCE_TYPE
                        }
                    }
                }]
            [/#list]
            [#break]

        [#case "igw"]
                [#local igwId = formatVPCIGWTemplateId()]
                [#local resources += {
                    "internetGateway" : {
                        "Id" : formatVPCIGWTemplateId(),
                        "Name" : core.FullName,
                        "Type" : AWS_VPC_IGW_RESOURCE_TYPE
                    },
                    "internetGatewayAttachement" : {
                        "Id" : formatId(AWS_VPC_IGW_RESOURCE_TYPE, AWS_VPC_IGW_ATTACHMENT_TYPE),
                        "Type" : AWS_VPC_IGW_ATTACHMENT_TYPE
                    }
                }]
            [#break]

        [#case "vpcendpoint"]
            [#break]

        [#default]  
            @cfException
                mode=listMode
                description="Unkown Engine Type"
                context=occurrence.Configuration.Solution
            /]
    [/#switch] 

    [#return 
        {
            "Resources" : resources,
            "Attributes" : {
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]

[#function getNetworkGatewayDestinationState occurrence parent ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local parentCore = parent.Core]
    [#local parentSolution = parent.Configuration.Solution ]
    [#local engine = parentSolution.Engine ]
    
    [#local resources = {} ]
    [#local zoneResources = {}]

    [#switch engine ]
        [#case "nat"] 
            [#break]

        [#case "igw"]
            [#break]

        [#case "vpcendpoint"]

            [#list solution.Services as service ]
                [#switch service ]
                    [#case "s3"]
                    [#case "dynamoDb" ]
                        [#local resources += {
                            "vpcEndPoint" + service.Id : {
                                "Id" : formatVPCEndPointId(service.Id),
                                "EndpointType" : "gateway",
                                "Type" : AWS_VPC_ENDPOINNT_RESOURCE_TYPE
                            }
                        }]
                        [#break]

                    [#default]
                        [#list zones as zone ]
                            [#local zoneResources =  
                                mergeObjects( 
                                    zoneResources, 
                                    {
                                        zone.Id : { 
                                            "vpcEndPoint" + service.Id : {
                                                "Id" : formatVPCEndPointId(service.Id),
                                                "EndpointType" : "endpoint",
                                                "Type" : AWS_VPC_ENDPOINNT_RESOURCE_TYPE
                                            }
                                        }
                                    }
                                )]
                        [/#list]
                [/#switch]
            [/#list]
            [#break]

        [#default]  
            @cfException
                mode=listMode
                description="Unkown Engine Type"
                context=occurrence.Configuration.Solution
            /]
    [/#switch] 

    [#return 
        {
            "Resources" : resources,
            "Attributes" : {
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]