[#-- ALB --]

[#-- Resources --]
[#assign AWS_ALB_RESOURCE_TYPE = "alb" ]
[#assign AWS_ALB_LISTENER_RESOURCE_TYPE = "listener" ]
[#assign AWS_ALB_LISTENER_RULE_RESOURCE_TYPE = "listenerRule" ]
[#assign AWS_ALB_TARGET_GROUP_RESOURCE_TYPE = "tg" ]

[#function formatALBId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_ALB_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatALBListenerId tier component source extensions...]
    [#return formatComponentResourceId(
                AWS_ALB_LISTENER_RESOURCE_TYPE,
                tier,
                component,
                extensions,
                source.Port)]
[/#function]

[#function formatALBListenerRuleId tier component source name extensions...]
    [#return formatComponentResourceId(
                AWS_ALB_LISTENER_RULE_RESOURCE_TYPE, 
                tier,
                component,
                extensions,
                source.Port,
                name)]
[/#function]

[#function formatALBTargetGroupId tier component source name extensions...]
    [#return formatComponentResourceId(
                AWS_ALB_TARGET_GROUP_RESOURCE_TYPE,
                tier,
                component,
                extensions,
                source.Port,
                name)]
[/#function]

[#function formatALBListenerSecurityGroupIngressId resourceId source ]
    [#return formatDependentSecurityGroupIngressId(
                resourceId,
                source.Port)]
[/#function]


[#-- Components --]
[#assign ALB_COMPONENT_TYPE = "alb"]
[#assign componentConfiguration +=
    {
        ALB_COMPONENT_TYPE : [
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

    [#local id = formatResourceId(AWS_ALB_RESOURCE_TYPE, core.Id) ]
    [#local internalFqdn = getExistingReference(id, DNS_ATTRIBUTE_TYPE) ]

    [#if (configuration.PortMappings![])?has_content]
        [#local mappingObject = configuration.PortMappings[0]?is_hash?then(
                configuration.PortMappings[0],
                {
                    "Mapping" : configuration.PortMappings[0]
                }
            )]
        [#if (ports[portMappings[mappingObject.Mapping].Source].Certificate)!false ]
            [#local certificateObject = getCertificateObject(configuration.Certificate!"", segmentId, segmentName) ]
            [#local hostName = getHostName(certificateObject, occurrence) ]
            
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
                    "Id" : id,
                    "Type" : AWS_ALB_RESOURCE_TYPE
                },
                "secgroup" : {
                    "Id" : formatSecurityGroupId(core.Id),
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
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
