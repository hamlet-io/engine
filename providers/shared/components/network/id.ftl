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
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Logging",
                "Children" : [
                    {
                        "Names" : "EnableFlowLogs",
                        "Description" : "Deprecated: Please use FlowLogs",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "FlowLogs",
                        "Description" : "Log flows across the network",
                        "Subobjects" : true,
                        "Children" : [
                            {
                                "Names" : "Action",
                                "Types" : STRING_TYPE,
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
                                        "Reference" : {
                                            "Schema" : "metaparameter",
                                            "Type" : LINK_METAPARAMETER_TYPE
                                        }
                                    },
                                    {
                                        "Names" : "Prefix",
                                        "Description" : "A prefix for the s3 bucket destination",
                                        "Types" : STRING_TYPE,
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
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "GenerateHostNames",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "Address",
                "Children" : [
                    {
                        "Names" : "CIDR",
                        "Types" : STRING_TYPE,
                        "Default" : "10.0.0.0/16"
                    }
                ]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Reference" : {
                    "Schema" : "metaparameter",
                    "Type" : LINK_METAPARAMETER_TYPE
                }
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Logging",
                        "Types" : STRING_TYPE,
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
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Public",
                "Description" : "Does the route table require Public IP internet access",
                "Types" : BOOLEAN_TYPE,
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
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Rules",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "Priority",
                        "Types" : NUMBER_TYPE,
                        "Required" : true
                    },
                    {
                        "Names" : "Action",
                        "Types" : STRING_TYPE,
                        "Default" : "deny",
                        "Values" : [ "allow", "deny" ]
                    },
                    {
                        "Names" : "Source",
                        "Description" : "Source of the network traffic",
                        "Children" : [
                            {
                                "Names" : "IPAddressGroups",
                                "Types" : ARRAY_OF_STRING_TYPE,
                                "Required" : true
                            },
                            {
                                "Names" : "Port",
                                "Description" : "Port or port range the source is coming from",
                                "Types" : STRING_TYPE,
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
                                "Types" : ARRAY_OF_STRING_TYPE,
                                "Required" : true
                            },
                            {
                                "Names" : "Port",
                                "Description" : "Port or port range the source is trying to access",
                                "Types" : STRING_TYPE,
                                "Required" : true
                            }
                        ]
                    },
                    {
                        "Names" : "ReturnTraffic",
                        "Description" : "If ACL is stateless add a return rule",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            }
        ]
    parent=NETWORK_COMPONENT_TYPE
    childAttribute="NetworkACLs"
    linkAttributes="NetworkACL"
/]
