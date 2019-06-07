[#-- Components --]
[#assign NETWORK_COMPONENT_TYPE = "network" ]
[#assign NETWORK_ROUTE_TABLE_COMPONENT_TYPE = "networkroute"]
[#assign NETWORK_ACL_COMPONENT_TYPE = "networkacl"]

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
        }
    }]
