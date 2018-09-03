[#-- ALB --]

[#-- Resources --]
[#assign AWS_LB_RESOURCE_TYPE = "lb" ]
[#assign AWS_ALB_RESOURCE_TYPE = "alb" ]

[#assign AWS_ALB_LISTENER_RESOURCE_TYPE = "listener" ]
[#assign AWS_ALB_LISTENER_RULE_RESOURCE_TYPE = "listenerRule" ]
[#assign AWS_ALB_TARGET_GROUP_RESOURCE_TYPE = "tg" ]

[#-- Components --]
[#assign LB_COMPONENT_TYPE = "lb" ]
[#assign LB_PORT_COMPONENT_TYPE = "lbport" ]

[#-- Deprecated Name - Kept for Backwards compatabilty of component naming --]
[#assign ALB_COMPONENT_TYPE = "alb" ]

[#assign componentConfiguration +=
    {
        LB_COMPONENT_TYPE   : {
            "Attributes" : [
                {
                    "Name" : "Logs",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Name" : "Engine",
                    "Type" : STRING_TYPE,
                    "Values" : ["application", "network", "classic"],
                    "Default" : "application"
                },
                {
                    "Name" : "IdleTimeout", 
                    "Type" : NUMBER_TYPE,
                    "Default" : 60
                }
                {
                    "Name" : "HealthCheckPort",
                    "Type" : STRING_TYPE,
                    "Default" : ""
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
        LB_PORT_COMPONENT_TYPE : [
            {
                "Name" : "IPAddressGroups",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Name" : "Certificate",
                "Type" : OBJECT_TYPE,
                "Default" : {}
            },
            {
                "Name" : "Mapping",
                "Type" : STRING_TYPE
            },
            {
                "Name" : "Path",
                "Type" : STRING_TYPE,
                "Default" : "default"
            },
            {
                "Name" : "Priority",
                "Type" : NUMBER_TYPE,
                "Default" : 100
            },
            {
                "Name" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Name" : "Authentication",
                "Children" : [
                    {
                        "Name" : "SessionCookieName",
                        "Type" : STRING_TYPE,
                        "Default" : "AWSELBAuthSessionCookie"
                    },
                    {
                        "Name" : "SessionTimeout",
                        "Type" : NUMBER_TYPE,
                        "Default" : 604800
                    }
                ]
            },
            {
                "Name" : "Redirect",
                "Children" : [
                    {
                        "Name" : "Protocol",
                        "Type" : STRING_TYPE,
                        "Values" : ["HTTPS", "#\{protocol}" ],
                        "Default" : "HTTPS"
                    },
                    {
                        "Name" : "Port",
                        "Type" : STRING_TYPE,
                        "Default" : "443"
                    },
                    {
                        "Name" : "Host",
                        "Type" : STRING_TYPE,
                        "Default" : "#\{host}"
                    },
                    {
                        "Name" : "Path",
                        "Type" : STRING_TYPE,
                        "Default" : "/#\{path}"
                    },
                    {
                        "Name" : "Query",
                        "Type" : STRING_TYPE,
                        "Default" : "#\{query}"
                    },
                    {
                        "Name" : "Permanent",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Name" : "Fixed",
                "Children" : [
                    {
                        "Name" : "Message",
                        "Type" : STRING_TYPE,
                        "Default" : "This application is currently unavailable. Please try again later."
                    },
                    {
                        "Name" : "ContentType",
                        "Type" : STRING_TYPE,
                        "Default" : "text/plain"
                    },
                    {
                        "Name" : "StatusCode",
                        "Type" : NUMBER_TYPE,
                        "Default" : 404
                    }
                ]
            },
            {
                "Name" : "Forward",
                "Children" : [
                    {
                        "Name" : "TargetType",
                        "Type" : STRING_TYPE,
                        "Values" : ["instance", "ip"],
                        "Default" : "instance"
                    },
                    {
                        "Name" : "SlowStartTime",
                        "Type" : NUMBER_TYPE,
                        "Default" : -1
                    },
                    {
                        "Name" : "StickinessTime",
                        "Type" : NUMBER_TYPE,
                        "Default" : -1
                    },
                    {
                        "Name" : "DeregistrationTimeout",
                        "Type" : NUMBER_TYPE,
                        "Default" : 30
                    }
                ]
            }
        ]
    }]

[#function getLBState occurrence]
    [#local core = occurrence.Core]

    [#if getExistingReference(formatResourceId(AWS_ALB_RESOURCE_TYPE, core.Id) )?has_content ]
        [#local id = formatResourceId(AWS_ALB_RESOURCE_TYPE, core.Id) ]
    [#else]
        [#local id = formatResourceId(AWS_LB_RESOURCE_TYPE, core.Id) ]
    [/#if]
    
    [#return
        {
            "Resources" : {
                "lb" : {
                    "Id" : id,
                    "Name" : core.FullName,
                    "ShortName" : core.ShortFullName,
                    "Type" : AWS_LB_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "INTERNAL_FQDN" : getExistingReference(id, DNS_ATTRIBUTE_TYPE)
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]

[#function getLBPortState occurrence parent]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local parentCore = parent.Core ]
    [#local parentSolution = parent.Configuration.Solution ]
    [#local parentState = parent.State ]

    [#local engine = parentSolution.Engine]
    [#local internalFqdn = parentState.Attributes["INTERNAL_FQDN"] ]
    [#local lbId = parentState.Resources["lb"].Id]

    [#local sourcePort = (ports[portMappings[solution.Mapping!core.SubComponent.Name].Source])!{} ]
    [#local destinationPort = (ports[portMappings[solution.Mapping!core.SubComponent.Name].Destination])!{} ]
    [#local listenerId = formatResourceId(AWS_ALB_LISTENER_RESOURCE_TYPE, parentCore.Id, sourcePort) ]

    [#local path = (solution.Path == "default")?then(
        "",
        solution.Path
    )]

    [#if (sourcePort.Certificate)!false ]
        [#local certificateObject = getCertificateObject(solution.Certificate, segmentQualifiers) ]
        [#local hostName = getHostName(certificateObject, occurrence) ]

        [#local fqdn = formatDomainName(hostName, certificateObject.Domain.Name)]
        [#local scheme = "https" ]
    [#else]
        [#local fqdn = internalFqdn ]
        [#local scheme ="http" ]
    [/#if]

    [#local url = scheme + "://" + fqdn  ]
    [#local internalUrl = scheme + "://" + internalFqdn ]
    
    [#return
        {
            "Resources" : {
                "listener" : {
                    "Id" : listenerId,
                    "Type" : AWS_ALB_LISTENER_RESOURCE_TYPE
                },
                "sg" : {
                    "Id" : formatDependentSecurityGroupId(listenerId),
                    "Name" : core.FullName,
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                },
                "listenerRule" : {
                    "Id" : formatResourceId(AWS_ALB_LISTENER_RULE_RESOURCE_TYPE, core.Id),
                    "Type" : AWS_ALB_LISTENER_RULE_RESOURCE_TYPE
                },
                "targetgroup" : {
                    "Id" : formatResourceId(AWS_ALB_TARGET_GROUP_RESOURCE_TYPE, occurrence.Core.Id),
                    "Name" : formatName(core.FullName),
                    "Type" : AWS_ALB_TARGET_GROUP_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "LB" : lbId,
                "ENGINE" : engine,
                "FQDN" : fqdn,
                "URL" : url + path,
                "INTERNAL_FQDN" : internalFqdn,
                "INTERNAL_URL" : internalUrl + path,
                "PATH" : path,
                "PORT" : sourcePort.Name,
                "SOURCE_PORT" : sourcePort.Name,
                "DESTINATION_PORT" : destinationPort.Name,
                "AUTH_CALLBACK_URL" : url + "/oauth2/idpresponse",
                "AUTH_CALLBACK_INTERNAL_URL" : internalUrl + "/oauth2/idpresponse"
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]
