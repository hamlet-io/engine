[#ftl]

[@addComponentDeployment
    type=LB_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addComponent
    type=LB_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A load balancer for virtual network based components"
            }
        ]
    attributes=
        [
            {
                "Names" : "Logs",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Engine",
                "Types" : STRING_TYPE,
                "Values" : ["application", "network", "classic"],
                "Default" : "application"
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Security",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Alert",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            },
            {
                "Names" : "IdleTimeout",
                "Types" : NUMBER_TYPE,
                "Default" : 60
            }
            {
                "Names" : "HealthCheckPort",
                "Types" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Names" : "Alerts",
                "Subobjects" : true,
                "Children" : alertChildrenConfiguration
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Reference" : {
                    "Schema" : "attributeset",
                    "Type" : LINK_ATTRIBUTESET_TYPE
                }
            },
            {
                "Names" : "WAF",
                "Children" : wafChildConfiguration
            }
        ]
/]

[@addChildComponent
    type=LB_PORT_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A specifc listener based on the client side network port"
            }
        ]
    attributes=
        [
            {
                "Names" : "IPAddressGroups",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "_localnet" ]
            },
            {
                "Names" : "Certificate",
                "Children" : certificateChildConfiguration
            },
            {
                "Names" : "HostFilter",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Mapping",
                "Types" : STRING_TYPE
            },
            {
                "Names" : "Path",
                "Types" : STRING_TYPE,
                "Default" : "default"
            },
            {
                "Names" : "Priority",
                "Types" : NUMBER_TYPE,
                "Default" : 100
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Reference" : {
                    "Schema" : "attributeset",
                    "Type" : LINK_ATTRIBUTESET_TYPE
                }
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Network",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            },
            {
                "Names" : "Authentication",
                "Children" : [
                    {
                        "Names" : "SessionCookieName",
                        "Types" : STRING_TYPE,
                        "Default" : "AWSELBAuthSessionCookie"
                    },
                    {
                        "Names" : "SessionTimeout",
                        "Types" : NUMBER_TYPE,
                        "Default" : 604800
                    }
                ]
            },
            {
                "Names" : "Redirect",
                "Children" : [
                    {
                        "Names" : "Protocol",
                        "Types" : STRING_TYPE,
                        "Values" : ["HTTPS", "#\{protocol}" ],
                        "Default" : "HTTPS"
                    },
                    {
                        "Names" : "Port",
                        "Types" : STRING_TYPE,
                        "Default" : "443"
                    },
                    {
                        "Names" : "Host",
                        "Types" : STRING_TYPE,
                        "Default" : "#\{host}"
                    },
                    {
                        "Names" : "Path",
                        "Types" : STRING_TYPE,
                        "Default" : "/#\{path}"
                    },
                    {
                        "Names" : "Query",
                        "Types" : STRING_TYPE,
                        "Default" : "#\{query}"
                    },
                    {
                        "Names" : "Permanent",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "Fixed",
                "Children" : [
                    {
                        "Names" : "Message",
                        "Types" : STRING_TYPE,
                        "Default" : "This application is currently unavailable. Please try again later."
                    },
                    {
                        "Names" : "ContentType",
                        "Types" : STRING_TYPE,
                        "Default" : "text/plain"
                    },
                    {
                        "Names" : "StatusCode",
                        "Types" : STRING_TYPE,
                        "Default" : "404"
                    }
                ]
            },
            {
                "Names" : "Forward",
                "Children" : [
                    {
                        "Names" : "TargetType",
                        "Types" : STRING_TYPE,
                        "Values" : ["instance", "ip"],
                        "Default" : "instance"
                    },
                    {
                        "Names" : "SlowStartTime",
                        "Types" : NUMBER_TYPE,
                        "Default" : -1
                    },
                    {
                        "Names" : "StickinessTime",
                        "Types" : NUMBER_TYPE,
                        "Default" : -1
                    },
                    {
                        "Names" : "DeregistrationTimeout",
                        "Types" : NUMBER_TYPE,
                        "Default" : 30
                    },
                    {
                        "Names" : "StaticEndpoints",
                        "Description" : "Static endpoints for the load balancing port",
                        "Children"  : [
                            {
                                "Names" : "Links",
                                "Subobjects" : true,
                                "Reference" : {
                                    "Schema" : "attributeset",
                                    "Type" : LINK_ATTRIBUTESET_TYPE
                                }
                            }
                        ]
                    }
                ]
            }
        ]
    parent=LB_COMPONENT_TYPE
    childAttribute="PortMappings"
    linkAttributes=["PortMapping","Port"]
/]
