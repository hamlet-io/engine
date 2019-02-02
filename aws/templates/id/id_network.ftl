[#-- Components --]
[#assign NETWORK_COMPONENT_TYPE = "network" ]

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
                    "Names" : "RouteTables",
                    "Subobjects" : true,
                    "Children" : [
                        {
                            "Names" : "PerAZ",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false 
                        },
                        {
                            "Names" : "Routes",
                            "Subobjects" : true,
                            "Children" : [
                                {
                                    "Names" : "DestinationNetwork",
                                    "Type" : ARRAY_OF_STRING_TYPE
                                },
                                {
                                    "Names" : "Links",
                                    "Subobjects" : true,
                                    "Children" : linkChildrenConfiguration
                                }
                            ]
                        }
                    ]
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
                }
            ]
        }
    }]

[#function getNetworkState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local vpcId = formatVPCTemplateId() ]

    [#local subnets = {} ]
    [#-- Define subnets --]
    [#list segmentObject.Network.Tiers.Order as tierId]
        [#assign networkTier = getTier(tierId) ]
        [#if ! (networkTier?has_content && networkTier.Network.Enabled ) ]
            [#continue]
        [/#if]

        [#list zones as zone]
            [#assign subnetId = formatSubnetId(networkTier, zone)]
            [#local subnets =  mergeObject( subnets, {
                zone.Id : {
                    networkTier.Id : {
                        "subnet" : {
                            "Id" : subnetId,
                            "Name" : formatSubnetName(networkTier, zone),
                            "Address" : addressOffset + (networkTier.Network.Index * addressesPerTier) + (zone.Index * addressesPerZone),
                            "Type" : AWS_VPC_SUBNET_TYPE
                        },
                        "routeTableAssoc" : {
                            "Id" : formatRouteTableAssociationId(subnetId),
                            "RouteTable" : routeTables[networkTier.Network.RouteTable],
                            "Type" : 
                        },
                        "networkACLAssoc" : {
                            "Id" : formatNetworkACLAssociationId(subnetId),
                            "NetworkACL" : networkACLs[networkTier.Network.NetworkACL]
                            "Type" :
                        }
                    }
                }
            }]
        [/#list]
    [/#list]


[#assign routeTableId = formatRouteTableId(routeTable,natPerAZ?string(zone.Id,""))]

    [#local result =
        {
            "Resources" : {
                "vpc" : {
                    "Id" : vpcId,
                    "Name" : formatVPCName(),
                    "Type" : AWS_VPC_RESOURCE_TYPE
                }
            } + 
            (solution.Logging.EnableFlowLogs)?then(
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
                }}
            )
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

