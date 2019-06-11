[#ftl]

[#assign componentConfiguration +=
    {
        LB_COMPONENT_TYPE   : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "A load balancer for virtual network based components"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                },
                {
                    "Type" : "Note",
                    "Value" : "Requires second deployment to complete configuration",
                    "Severity" : "warning"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Logs",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Engine",
                    "Type" : STRING_TYPE,
                    "Values" : ["application", "network", "classic"],
                    "Default" : "application"
                },
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration + [
                        {
                            "Names" : "Security",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
                },
                {
                    "Names" : "IdleTimeout",
                    "Type" : NUMBER_TYPE,
                    "Default" : 60
                }
                {
                    "Names" : "HealthCheckPort",
                    "Type" : STRING_TYPE,
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
                    "Children" : linkChildrenConfiguration
                }
            ],
            "Components" : [
                {
                    "Type" : LB_PORT_COMPONENT_TYPE,
                    "Component" : "PortMappings",
                    "Link" : ["PortMapping","Port"]
                }
            ]
        },
        LB_PORT_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "A specifc listener based on the client side network port"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "IPAddressGroups",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Certificate",
                    "Children" : certificateChildConfiguration
                },
                {
                    "Names" : "HostFilter",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Mapping",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "Path",
                    "Type" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Priority",
                    "Type" : NUMBER_TYPE,
                    "Default" : 100
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "Authentication",
                    "Children" : [
                        {
                            "Names" : "SessionCookieName",
                            "Type" : STRING_TYPE,
                            "Default" : "AWSELBAuthSessionCookie"
                        },
                        {
                            "Names" : "SessionTimeout",
                            "Type" : NUMBER_TYPE,
                            "Default" : 604800
                        }
                    ]
                },
                {
                    "Names" : "Redirect",
                    "Children" : [
                        {
                            "Names" : "Protocol",
                            "Type" : STRING_TYPE,
                            "Values" : ["HTTPS", "#\{protocol}" ],
                            "Default" : "HTTPS"
                        },
                        {
                            "Names" : "Port",
                            "Type" : STRING_TYPE,
                            "Default" : "443"
                        },
                        {
                            "Names" : "Host",
                            "Type" : STRING_TYPE,
                            "Default" : "#\{host}"
                        },
                        {
                            "Names" : "Path",
                            "Type" : STRING_TYPE,
                            "Default" : "/#\{path}"
                        },
                        {
                            "Names" : "Query",
                            "Type" : STRING_TYPE,
                            "Default" : "#\{query}"
                        },
                        {
                            "Names" : "Permanent",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        }
                    ]
                },
                {
                    "Names" : "Fixed",
                    "Children" : [
                        {
                            "Names" : "Message",
                            "Type" : STRING_TYPE,
                            "Default" : "This application is currently unavailable. Please try again later."
                        },
                        {
                            "Names" : "ContentType",
                            "Type" : STRING_TYPE,
                            "Default" : "text/plain"
                        },
                        {
                            "Names" : "StatusCode",
                            "Type" : STRING_TYPE,
                            "Default" : "404"
                        }
                    ]
                },
                {
                    "Names" : "Forward",
                    "Children" : [
                        {
                            "Names" : "TargetType",
                            "Type" : STRING_TYPE,
                            "Values" : ["instance", "ip"],
                            "Default" : "instance"
                        },
                        {
                            "Names" : "SlowStartTime",
                            "Type" : NUMBER_TYPE,
                            "Default" : -1
                        },
                        {
                            "Names" : "StickinessTime",
                            "Type" : NUMBER_TYPE,
                            "Default" : -1
                        },
                        {
                            "Names" : "DeregistrationTimeout",
                            "Type" : NUMBER_TYPE,
                            "Default" : 30
                        }
                    ]
                }
            ]
        }
    }]
