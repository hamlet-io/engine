[#ftl]

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
                        "Names" : "FlowLogs",
                        "Description" : "Log flows across the network",
                        "SubObjects" : true,
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
                                        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                                    },
                                    {
                                        "Names" : "Prefix",
                                        "Description" : "A prefix for the s3 bucket destination",
                                        "Types" : STRING_TYPE,
                                        "Default" : "FlowLogs/"
                                    },
                                    {
                                        "Names": "IncludeInPrefix",
                                        "Description": "Context specific details to include in the prefix",
                                        "Types": ARRAY_OF_STRING_TYPE,
                                        "Values" : [
                                            "Prefix",
                                            "FullAbsolutePath",
                                            "Id"
                                        ],
                                        "Default": [
                                            "Prefix",
                                            "FullAbsolutePath",
                                            "Id"
                                        ]
                                    }
                                ]
                            }
                        ]
                    },
                    {
                        "Names" : "DNSQuery",
                        "Description" : "Log DNS Queries made in the vpc",
                        "SubObjects" : true,
                        "Children" : [
                            {
                                "Names" : "DestinationType",
                                "Types" : STRING_TYPE,
                                "Description" : "The destination type to send the logs to",
                                "Values" : [ "log", "s3", "datafeed" ],
                                "Default" : "s3"
                            },
                            {
                                "Names" : "s3",
                                "Description" : "s3 specific destination configuration",
                                "Children" : [
                                    {
                                        "Names" : "Link",
                                        "Description" : "A link to the s3 bucket destination",
                                        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                                    }
                                ]
                            },
                            {
                                "Names" : "datafeed",
                                "Description" : "datafeed specific destination configuration",
                                "Children" : [
                                    {
                                        "Names" : "Link",
                                        "Description" : "A link to the datafeed destination",
                                        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
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
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Logging",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Network",
                        "Description" : "The network profile rules applied to the default access control groups",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            }
        ]
/]

[@addComponentDeployment
    type=NETWORK_COMPONENT_TYPE
    defaultGroup="segment"
    defaultPriority=20
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
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Description" : "Enable the rule",
                        "Types": BOOLEAN_TYPE,
                        "Default": true
                    },
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
