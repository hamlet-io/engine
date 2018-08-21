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
                    "Default" : false
                },
                {
                    "Name" : "Engine",
                    "Default" : "application"
                },
                {
                    "Name" : "IdleTimeout", 
                    "Default" : 60
                }
                {
                    "Name" : "HealthCheckPort",
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
                "Default" : []
            },
            {
                "Name" : "Certificate",
                "Default" : {}
            },
            {
                "Name" : "Mapping"
            },
            {
                "Name" : "TargetType",
                "Default" : "instance"
            },
            {
                "Name" : "Path",
                "Default" : "default"
            },
            {
                "Name" : "Priority",
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
                        "Default" : "AWSELBAuthSessionCookie"
                    },
                    {
                        "Name" : "SessionTimeout",
                        "Default" : 604800
                    }
                ]
            },
            {
                "Name" : "Redirect",
                "Children" : [
                    {
                        "Name" : "Protocol",
                        "Default" : "https"
                    },
                    {
                        "Name" : "Port",
                        "Default" : "443"
                    },
                    {
                        "Name" : "Host",
                        "Default" : "#\{host}"
                    },
                    {
                        "Name" : "Path",
                        "Default" : "#\{path}"
                    },
                    {
                        "Name" : "Query",
                        "Default" : "#\{query}"
                    },
                    {
                        "Name" : "Permanent",
                        "Default" : false
                    }
                ]
            },
            {
                "Name" : "Fixed",
                "Children" : [
                    {
                        "Name" : "Message",
                        "Default" : "This application is currently unavailable. Please try again later."
                    },
                    {
                        "Name" : "ContentType",
                        "Default" : "text/plain"
                    },
                    {
                        "Name" : "StatusCode",
                        "Default" : 200
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
