[#ftl]

[@addComponent
    type=NETWORK_COMPONENT_TYPE
    properties=
        [
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
        ]
    attributes=
        [
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
        ]
/]

[@addChildComponent
    type=NETWORK_ROUTE_TABLE_COMPONENT_TYPE
    properties=
        [
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
        ]
    attributes=
        [
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
            }
        ]
    parent=NETWORK_COMPONENT_TYPE
    childAttribute="RouteTables"
    linkAttributes="RouteTable"
/]

[@addChildComponent
    type=NETWORK_ACL_COMPONENT_TYPE
    properties=
        [
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
        ]
    attributes=
        [
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
    parent=NETWORK_COMPONENT_TYPE
    childAttribute="NetworkACLs"
    linkAttributes="NetworkACL"
/]
