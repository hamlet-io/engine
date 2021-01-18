[#ftl]

[@addComponentDeployment
    type=NETWORK_COMPONENT_TYPE
    defaultGroup="segment"
    defaultPriority=20
/]


[@addComponent
    type=NETWORK_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A virtual network segment used by private resources"
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
                        "Description" : "Deprecated: Please use FlowLogs",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "FlowLogs",
                        "Description" : "Log flows across the network",
                        "Subobjects" : true,
                        "Children" : [
                            {
                                "Names" : "Action",
                                "Type" : STRING_TYPE,
                                "Description" : "The action to capture in the flow log",
                                "Values" : [ "accept", "reject", "any" ],
                                "Mandatory" : true
                            },
                            {
                                "Names" : "DestinationType",
                                "Types" : STRING_TYPE,
                                "Description" : "The destination type to send the logs to",
                                "Values" : [ "log", "s3" ],
                                "Default" : "s3"
                            },
                            {
                                "Names" : "s3",
                                "Description" : "s3 specific destination configuration",
                                "Children" : [
                                    {
                                        "Names" : "Link",
                                        "Description" : "A link to the s3 bucket destination",
                                        "Children" : linkChildrenConfiguration
                                    },
                                    {
                                        "Names" : "Prefix",
                                        "Description" : "A prefix for the s3 bucket destination",
                                        "Type" : STRING_TYPE,
                                        "Default" : "FlowLogs/"
                                    }
                                ]
                            }
                        ]
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
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Logging",
                        "Type" : STRING_TYPE,
                        "Default" : "default"
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
                    },
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
