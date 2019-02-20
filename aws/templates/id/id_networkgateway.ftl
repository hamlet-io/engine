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
                },
                {
                    "Names" : "SourceIPAddressGroups",
                    "Description" : "IP Address Groups which can access this gateway",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : [ "_localnet" ]
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
                    "Description" : "An IP Address Group reference",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "NetworkEndpointGroups",
                    "Description" : "A cloud provider service group reference",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                { 
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
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

    [#if multiAZ ]
        [#local resourceZones = zones ]
    [#else]
        [#local resourceZones = [ zones[0] ]]
    [/#if]

    [#-- elastic IP address Allocation --]
    [#switch engine ]
        [#case "natgw" ]
        [#case "instance" ]
            [#list resourceZones as zone ]
                [#local eipId = legacyVpc?then(
                                    formatResourceId(AWS_EIP_RESOURCE_TYPE, core.Tier.Id, core.Component.Id, zone.Id),
                                    formatResourceId(AWS_EIP_RESOURCE_TYPE, core.Id, zone.Id))]    
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
        [#case "natgw"] 

            [#list resourceZones as zone]
                [#local natGatewayId = legacyVpc?then(
                                            formatNATGatewayId(core.Tier.Id, zone.Id),
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
                [#local resources += {
                    "sg" : {
                        "Id" : formatDependentSecurityGroupId(core.Id),
                        "Name" : core.FullName,
                        "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                    }
                }]
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
    
    [#if multiAZ || engine == "vpcendpoint" ]
        [#local resourceZones = zones ]
    [#else]
        [#local resourceZones = [zones[0]] ]
    [/#if]

    [#local resources = {} ]

    [#switch engine ]
        [#case "natgw"]
            [#break]

        [#case "igw"]
            [#break]

        [#case "vpcendpoint"]

            [#local endpointZones = {} ]
            [#list resourceZones as zone]
                [#local networkEndpoints = getNetworkEndpoints(solution.NetworkEndpointGroups, zone.Id, region)]
                [#list networkEndpoints as id, networkEndpoint  ]
                    [#local endpointTypeZones = endpointZones[id]![] ]
                    [#local endpointZones += { id : endpointTypeZones + [ zone.Id ] }]
                    [#local resources = mergeObjects( resources, {
                        "vpcEndpoints" : {
                            "vpcEndpoint" + id : { 
                                "Id" : formatResourceId(AWS_VPC_ENDPOINNT_RESOURCE_TYPE, core.Id, replaceAlphaNumericOnly(id, "X")),
                                "EndpointType" : networkEndpoint.Type?lower_case,
                                "EndpointZones" : endpointZones[id],
                                "ServiceName" : networkEndpoint.ServiceName,
                                "Type" : AWS_VPC_ENDPOINNT_RESOURCE_TYPE
                            }
                        }
                    })]
                [/#list]
            [/#list]
            [#break]

        [#default]  
            [@cfException
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