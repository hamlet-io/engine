[#-- ALB --]

[#-- Resources --]
[#assign AWS_LB_RESOURCE_TYPE = "lb" ]
[#assign AWS_ALB_RESOURCE_TYPE = "alb" ]

[#assign AWS_ALB_LISTENER_RESOURCE_TYPE = "listener" ]
[#assign AWS_ALB_LISTENER_RULE_RESOURCE_TYPE = "listenerRule" ]
[#assign AWS_ALB_TARGET_GROUP_RESOURCE_TYPE = "tg" ]

[#function formatALBListenerRuleId occurrence name ]
    [#return formatResourceId(AWS_ALB_LISTENER_RULE_RESOURCE_TYPE, occurrence.Core.Id, name) ]
[/#function]

[#function formatALBTargetGroupId occurrence name ]
    [#return formatResourceId(AWS_ALB_TARGET_GROUP_RESOURCE_TYPE, occurrence.Core.Id, name) ]
[/#function]

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

    [#local parentSolution = parent.Configuration.Solution ]
    [#local parentState = parent.State ]

    [#local engine = parentSolution.Engine]
    [#local internalFqdn = parentState.Attributes["INTERNAL_FQDN"] ]
    [#local lbId = parentState.Resources["lb"].Id]

    [#local sourcePort = (ports[portMappings[solution.Mapping!core.SubComponent.Name].Source])!{} ]

    [#local id = formatResourceId(AWS_ALB_LISTENER_RESOURCE_TYPE, core.Id) ]

    [#if (sourcePort.Certificate)!false ]
        [#local certificateObject = getCertificateObject(solution.Certificate, segmentQualifiers) ]
        [#local hostName = getHostName(certificateObject, occurrence) ]

        [#local fqdn = formatDomainName(hostName, certificateObject.Domain.Name)]
        [#local scheme = "https" ]
    [#else]
        [#local fqdn = internalFqdn ]
        [#local scheme ="http" ]
    [/#if]
    [#return
        {
            "Resources" : {
                "listener" : {
                    "Id" : id,
                    "Type" : AWS_ALB_LISTENER_RESOURCE_TYPE
                },
                "sg" : {
                    "Id" : formatDependentSecurityGroupId(id),
                    "Name" : core.FullName,
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                },
                "targetgroups" : {
                    "default" : {
                        "Id" : formatALBTargetGroupId(occurrence, "default"),
                        "Name" : formatName(core.FullName, "default"),
                        "Type" : AWS_ALB_TARGET_GROUP_RESOURCE_TYPE
                    }
                }
            },
            "Attributes" : {
                "LB" : lbId,
                "ENGINE" : engine,
                "FQDN" : fqdn,
                "URL" : scheme + "://" + fqdn,
                "INTERNAL_FQDN" : internalFqdn,
                "INTERNAL_URL" : scheme + "://" + internalFqdn,
                "PORT" : sourcePort.Name
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]
