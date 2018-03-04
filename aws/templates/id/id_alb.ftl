[#-- ALB --]

[#assign ALB_RESOURCE_TYPE = "alb" ]
[#assign ALB_LISTENER_RESOURCE_TYPE = "listener" ]
[#assign ALB_LISTENER_RULE_RESOURCE_TYPE = "listenerRule" ]
[#assign ALB_TARGET_GROUP_RESOURCE_TYPE = "tg" ]

[#function formatALBId tier component extensions...]
    [#return formatComponentResourceId(
                ALB_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatALBListenerId tier component source extensions...]
    [#return formatComponentResourceId(
                ALB_LISTENER_RESOURCE_TYPE,
                tier,
                component,
                extensions,
                source.Port)]
[/#function]

[#function formatALBListenerRuleId tier component source name extensions...]
    [#return formatComponentResourceId(
                ALB_LISTENER_RULE_RESOURCE_TYPE, 
                tier,
                component,
                extensions,
                source.Port,
                name)]
[/#function]

[#function formatALBTargetGroupId tier component source name extensions...]
    [#return formatComponentResourceId(
                ALB_TARGET_GROUP_RESOURCE_TYPE,
                tier,
                component,
                extensions,
                source.Port,
                name)]
[/#function]

[#function formatALBSecurityGroupId tier component extensions...]
    [#return formatComponentSecurityGroupId(
                tier,
                component,
                extensions)]
[/#function]

[#function formatALBListenerSecurityGroupIngressId resourceId source ]
    [#return formatDependentSecurityGroupIngressId(
                resourceId,
                source.Port)]
[/#function]

[#assign componentConfiguration +=
    {
        "alb" : [
            {
                "Name" : "Logs",
                "Default" : false
            },
            {
                "Name" : "PortMappings",
                "Default" : []
            },
            {
                "Name" : "IPAddressGroups",
                "Default" : []
            },
            {
                "Name" : "Certificate",
                "Default" : {}
            }
        ]
    }]
    
[#function getALBState occurrence]
    [#local core = occurrence.Core]
    [#local configuration = occurrence.Configuration]

    [#local id = formatALBId(core.Tier, core.Component, occurrence) ]
    [#local internalFqdn = getExistingReference(id, DNS_ATTRIBUTE_TYPE) ]

    [#if (configuration.PortMappings![])?has_content]
        [#local portMapping = configuration.PortMappings[0]?is_hash?then(
                configuration.PortMappings[0],
                {
                    "Mapping" : configuration.PortMappings[0]
                }
            )]
        [#if (ports[portMappings[mappingObject.Mapping].Source].Certificate)!false ]
            [#local certificateObject = getCertificateObject(configuration.Certificate!"", segmentId, segmentName) ]
            [#local hostName = getHostName(certificateObject, core.Tier, core.Component, occurrence) ]
            
            [#local fqdn = formatDomainName(hostName, certificateObject.Domain.Name)]
            [#local scheme = "https" ]
        [#else]
            [#local fqdn = internalFqdn ]
            [#local scheme ="http" ]
        [/#if]
    [#else]
        [#local fqdn = "" ]
        [#local scheme = "http?" ]
    [/#if]
    [#return
        {
            "Resources" : {
                "lb" : {
                    "Id" : id
                }
            },
            "Attributes" : {
                "FQDN" : fqdn,
                "URL" : scheme + "://" + fqdn,
                "INTERNAL_FQDN" : internalFqdn,
                "INTERNAL_URL" : scheme + "://" + internalFqdn
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]
