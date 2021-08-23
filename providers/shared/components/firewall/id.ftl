[#ftl]

[@addComponentDeployment
    type=FIREWALL_COMPONENT_TYPE
    defaultGroup="segment"
    defaultPriority=60
/]

[@addComponent
    type=FIREWALL_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A network security service to filter inbound and outbound traffic"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Types" : STRING_TYPE,
                "Values" : [ "network" ],
                "Mandatory" : true
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
            },
            {
                "Names" : "Logging",
                "Description" : "Configure where logs are directed",
                "Children" : [
                    {
                        "Names" : "Events",
                        "Description" : "The log events to capture on the firewall",
                        "Values" : [ "all", "alert-only" ],
                        "Default" : "alert-only"
                    },
                    {
                        "Names" : "DestinationType",
                        "Description" : "The destination to forward logs to",
                        "Values" : [ "log", "s3", "datafeed" ],
                        "Default" : "log"
                    },
                    {
                        "Names" : "destinationType:s3",
                        "Description" : "Specific configuration for S3 logging",
                        "Children" : [
                            {
                                "Names" : "Link",
                                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                            },
                            {
                                "Names" : "Prefix",
                                "Description" : "A prefix to append to logs",
                                "AttributeSet" : CONTEXTPATH_ATTRIBUTESET_TYPE
                            }
                        ]
                    },
                    {
                        "Names" : "destinationType:datafeed",
                        "Description" : "Specific configuration for datafeed logging",
                        "Children" : [
                            {
                                "Names" : "Link",
                                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                            }
                        ]
                    }
                ]
            }
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            }
        ]
/]

[@addChildComponent
    type=FIREWALL_RULE_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A firewall policy rule applied by the firewall"
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
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Action",
                "Description" : "The action to perform on a match of this rule",
                "Values" : [ "pass", "drop", "inspect", "alert", "monitor" ]
            },
            {
                "Names" : "Priority",
                "Description" : "The priority of the rule - lowest number wins or use default as last rule",
                "Types" : [ NUMBER_TYPE, STRING_TYPE ],
                "Mandatory" : true
            },
            {
                "Names" : "Type",
                "Description" : "The type of rule to be applied",
                "Types" : STRING_TYPE,
                "Values" : [ "NetworkTuple", "HostFilter", "Complex" ],
                "Default" : "NetworkTuple"
            },
            {
                "Names" : "Inspection",
                "Description" : "How to inspect network flows through the firewall",
                "Types" : STRING_TYPE,
                "Values" : [ "Stateful", "Stateless" ],
                "Default" : "Stateful"
            },
            {
                "Names" : "NetworkTuple",
                "Description" : "Rule configuration for the networkTuple rule type",
                "Children" : [
                    {
                        "Names" : "Source",
                        "Description" : "The details of the network traffic source",
                        "Children" : [
                            {
                                "Names" : "Port",
                                "Description" : "The name of the Port reference",
                                "Types" : STRING_TYPE,
                                "Default" : "any"
                            },
                            {
                                "Names" : "IPAddressGroups",
                                "Description" : "The IP address group names for the source",
                                "Types" : ARRAY_OF_STRING_TYPE,
                                "Default" : [ "_global" ]
                            },
                            {
                                "Names" : "Links",
                                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                            }
                        ]
                    },
                    {
                        "Names" : "Destination",
                        "Description" : "The details of the network traffic destinations",
                        "Children" : [
                            {
                                "Names" : "Port",
                                "Description" : "The name of the Port reference",
                                "Types" : STRING_TYPE
                            },
                            {
                                "Names" : "IPAddressGroups",
                                "Description" : "The IP address group names for the source",
                                "Types" : ARRAY_OF_STRING_TYPE
                            },
                            {
                                "Names" : "Links",
                                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                            }
                        ]
                    }
                ]
            },
            {
                "Names" : "HostFilter",
                "Description" : "Filter traffic based on Host requested",
                "Children" : [
                    {
                        "Names" : "LinkEndpoints",
                        "Description" : "Links to components for Host endpoints",
                        "SubObjects" : true,
                        "Children" : [
                            {
                                "Names" : "Link",
                                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                            },
                            {
                                "Names" : "Attribute",
                                "Description" : "The link Attribute to get the host from",
                                "Types" : STRING_TYPE,
                                "Default" : "FQDN"
                            }
                        ]
                    },
                    {
                        "Names" : "Hosts",
                        "Description" : "A collection of hosts to include use *. for wilcard domains",
                        "Types" : ARRAY_OF_STRING_TYPE
                    },
                    {
                        "Names" : "Protocols",
                        "Description" : "The protocols to inspect host names for",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Values" : [ "http", "tls_sni", "dns" ],
                        "Default" : [ "http", "tls_sni" ]
                    }
                ]
            },
            {
                "Names" : "Complex",
                "Description" : "Complex rule matching and processing",
                "Children" : [
                    {
                        "Names" : "Extensions",
                        "Description" : "A list of extensions to use for rule generation",
                        "Types" : ARRAY_OF_STRING_TYPE
                    },
                    {
                        "Names" : "Links",
                        "Description" : "Links to be used as part of the extension",
                        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                    },
                    {
                        "Names" : "IPAddressGroups",
                        "Description" : "A collection of IP AddressGroups to use during complex processing",
                        "Types" : ARRAY_OF_STRING_TYPE
                    },
                    {
                        "Names" : "Ports",
                        "Description" : "A collection of ports to use during complex processing",
                        "Types" : ARRAY_OF_STRING_TYPE
                    }
                ]
            }
        ]
    parent=FIREWALL_COMPONENT_TYPE
    childAttribute="Rules"
    linkAttributes="Rule"
/]
