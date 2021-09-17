[#ftl]

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
                "Description" : "Enable request logging for requests",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Engine",
                "Description" : "The type of load balancer - application: http based traffic - network: tcp/udp traffic",
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
                "Description" : "How long connections can remain idle before they are dropped",
                "Types" : NUMBER_TYPE,
                "Default" : 60
            }
            {
                "Names" : "HealthCheckPort",
                "Description" : "For classic engine the port to run health checks from",
                "Types" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Names" : "Alerts",
                "Description" : "Alerting rules based on metrics generated by the lb",
                "SubObjects" : true,
                "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "WAF",
                "Description" : "Web Application Firewall Integration",
                "Children" : wafChildConfiguration
            }
        ]
/]

[@addComponentDeployment
    type=LB_COMPONENT_TYPE
    defaultGroup="solution"
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
                "Description" : "A list of IP Address Groups that can access this port",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "_localnet" ]
            },
            {
                "Names" : [ "Certificate", "Hostname" ],
                "Description" : "The configuration of the hostname used for this lb port rule",
                "Children" : certificateChildConfiguration
            },
            {
                "Names" : "HostFilter",
                "Description" : "Should the http host be considered when the rule is evaluated",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Mapping",
                "Description" : "The Source Destination Port mapping between the frontend and backend",
                "Types" : STRING_TYPE
            },
            {
                "Names" : "Path",
                "Description" : "The http path the rule will be matched on",
                "Types" : STRING_TYPE,
                "Default" : "default"
            },
            {
                "Names" : "Priority",
                "Description" : "The priority order for the rule - highest wins. Can also set _default to set the final rule",
                "Types" : [ NUMBER_TYPE, STRING_TYPE ],
                "Default" : 100
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
                        "Names" : "Network",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            },
            {
                "Names" : "Authentication",
                "Description" : "Enable LB integrated authentication for the port rule",
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
                "Description" : "When the rule matches send a redirect response to the client",
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
                "Description" : "When the rule is matched send a fixed http response to the client",
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
                "Description" : "When the rule matches forward the request to a registered backend",
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
                                "SubObjects" : true,
                                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
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
