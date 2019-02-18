[#-- Components --]
[#assign NETWORK_GATEWAY_COMPONENT_TYPE = "gateway"]
[#assign NETWORK_GATEWAY_DESTINATION_COMPONENT_TYPE = "gatewaydestination"]

[#assign componentConfiguration +=
    {
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
                },
                {
                    "Names" : "PerAZ",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true 
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
                    "Type" : STRING_TYPE,
                    "Values" : [ "instance", "natgw", "igw", "vpcendpoint" ],
                    "Required" : true
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
                    "Description" : "An IP Address Group reference"
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "NetworkEndpointGroups",
                    "Description" : "A cloud provider service group reference",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        }
    }]

[#function getNetworkGatewayState occurrence ]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]
    [#local engine = solution.Engine ]
    [#local resources = {} ]
    [#local zoneResources = {}]

    [#assign legacyVpc = getVpcLgeacyStatus() ]

    [#if solution.PerAZ ]
        [#if solnMultiAZ ]
            [#local resourceZones = zones ]
        [#else]
            [#local resourceZones = zones[0]]
        [/#if]
    [#else]
        [#local resourceZones = [
                { 
                    "Id" : "regional"
                } 
            ]]
    [/#if]

    [#-- elastic IP address Allocation --]
    [#switch engine ]
        [#case "nat" ]
        [#case "instance" ]
            [#list resourceZones as zone ]
                [#local eipId = legacyVpc?then(
                                    formatResourceId(AWS_EIP_RESOURCE_TYPE, core.Tier.Id, core.Component.Id, zone),
                                    formatResourceId(AWS_EIP_RESOURCE_TYPE, core.Id, zone)]    
                [#local zoneResources = mergeObjects( zoneResources,
                        {
                            zone.Id : {
                                "eip" : {
                                    "Id" : eipId,
                                    "Type" : AWS_EIP_RESOURCE_TYPE
                                }
                            }
                        } )]
            [/#list]
            [#break]
    [/#switch]

    [#switch engine ]
        [#case "nat"] 

            [#list resourceZones as zone]
                [#local natGatewayId = legacyVpc?then(
                                            formatNATGatewayId(tier, zone),
                                            formatResourceId(AWS_VPC_NAT_GATEWAY_RESOURCE_TYPE, core.Id, zone.Id)
                )]

                [#local zoneResources = mergeObjects(zoneResources,
                        {
                            zone.Id : {
                                "natGateway" : {
                                    "Id" : natGatewayId,
                                    "Name" : formatName(core.FullName, zone.Name),
                                    "Type" : AWS_VPC_NAT_GATEWAY_RESOURCE_TYPE
                                }
                            }
                        })]
            [/#list]
            [#break]

        [#case "igw"]
            [#if !legacyVpc ]
                [#local resources += {
                    "internetGateway" : {
                        "Id" : formatResourceId(AWS_VPC_IGW_RESOURCE_TYPE, core.Id),
                        "Name" : core.FullName,
                        "Type" : AWS_VPC_IGW_RESOURCE_TYPE
                    },
                    "internetGatewayAttachement" : {
                        "Id" : formatId(AWS_VPC_IGW_ATTACHMENT_TYPE, core.Id),
                        "Type" : AWS_VPC_IGW_ATTACHMENT_TYPE
                    }
                }]
            [/#if]
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
            "Resources" : 
                resources + 
                { 
                    "Zones" : zoneResources 
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

[#function getNetworkGatewayDestinationState occurrence parent ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local parentCore = parent.Core]
    [#local parentSolution = parent.Configuration.Solution ]
    [#local engine = parentSolution.Engine ]
    
    [#if parentSolution.PerAZ ]
        [#if solnMultiAZ ]
            [#local resourceZones = zones ]
        [#else]
            [#local resourceZones = zones[0]]
        [/#if]
    [#else]
        [#local resourceZones = [
                { 
                    "Id" : "regional"
                } 
            ]]
    [/#if]

    [#local resources = {} ]
    [#local zoneResources = {}]

    [#switch engine ]
        [#case "nat"]
            [#break]

        [#case "igw"]
            [#break]

        [#case "vpcendpoint"]

            [#list resourceZones as zone]
                [#local networkEndpoints = getNetworkEndpoints(solution.NetworkEndpointGroups, region, zone)]
                [#list networkEndpoints as id, networkEndpoint  ]
                    [#switch networkEndpoint.Type ]
                        [#case "interface" ]
                            [#local resources = mergeObjects( resources, {
                                "vpcEndpoints" : {
                                    zone.Id : {
                                        "vpcEndpoint" + id : { 
                                            "Id" : formatResourceId(AWS_VPC_ENDPOINNT_RESOURCE_TYPE, core.Id, id, zone.Id),
                                            "EndpointType" : networkEndpoint.Type,
                                            "ServiceName" : networkEndpoint.ServiceName,
                                            "Type" : AWS_VPC_ENDPOINNT_RESOURCE_TYPE
                                        }
                                    }
                                }
                            }]
                            [#break]
                        [#case "gateway" ]
                            [#local resources = mergeObjects( resources, {
                                "vpcEndpoints" : {
                                    "regional" : {
                                        "vpcEndpoint" + id : { 
                                            "Id" : formatResourceId(AWS_VPC_ENDPOINNT_RESOURCE_TYPE, core.Id, id),
                                            "EndpointType" : networkEndpoint.Type,
                                            "ServiceName" : networkEndpoint.ServiceName,
                                            "Type" : AWS_VPC_ENDPOINNT_RESOURCE_TYPE
                                        }
                                    }
                                }
                            }]
                            [#break]
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