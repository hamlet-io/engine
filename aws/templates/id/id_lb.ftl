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
                    "Children" : [
                        {
                            "Names" : "SecurityProfile",
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
                    "Type" : OBJECT_TYPE,
                    "Default" : {}
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

    [#local targetGroupId = formatResourceId(AWS_ALB_TARGET_GROUP_RESOURCE_TYPE, core.Id) ]
    [#local defaultTargetGroupId = formatResourceId(AWS_ALB_TARGET_GROUP_RESOURCE_TYPE, "default", parentCore.Id, sourcePort ) ]
    [#local defaultTargetGroupName = formatName("default", parentCore.FullName, sourcePort )]

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

    [#switch parentSolution.Engine ]
        [#case "application" ]
            [#local targetGroupArn = getExistingReference(targetGroupId, ARN_ATTRIBUTE_TYPE)]
            [#break]
        [#case "network" ]
            [#local targetGroupArn = getExistingReference(defaultTargetGroupId, ARN_ATTRIBUTE_TYPE)]
            [#break]
        [#default]
            [#local targetGroupArn = ""]
    [/#switch]

    [#return
        {
            "Resources" : {
                "listener" : {
                    "Id" : listenerId,
                    "Type" : AWS_ALB_LISTENER_RESOURCE_TYPE
                },
                "sg" : {
                    "Id" : formatDependentSecurityGroupId(listenerId),
                    "Name" : formatName(parentCore.FullName, sourcePort),
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                },
                "listenerRule" : {
                    "Id" : formatResourceId(AWS_ALB_LISTENER_RULE_RESOURCE_TYPE, parentCore.Id, sourcePort, solution.Priority),
                    "Type" : AWS_ALB_LISTENER_RULE_RESOURCE_TYPE
                },
                "targetgroup" : {
                    "Id" : targetGroupId,
                    "Name" : formatName(core.FullName),
                    "Type" : AWS_ALB_TARGET_GROUP_RESOURCE_TYPE
                },
                "defaulttg" : {
                    "Id" : defaultTargetGroupId,
                    "Name" : defaultTargetGroupName,
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
                "AUTH_CALLBACK_INTERNAL_URL" : internalUrl + "/oauth2/idpresponse",
                "TARGET_GROUP_ARN" : targetGroupArn
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]
