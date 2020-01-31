[#ftl]

[#macro aws_lb_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution ]

    [#if getExistingReference(formatResourceId(AWS_ALB_RESOURCE_TYPE, core.Id) )?has_content ]
        [#local id = formatResourceId(AWS_ALB_RESOURCE_TYPE, core.Id) ]
    [#else]
        [#local id = formatResourceId(AWS_LB_RESOURCE_TYPE, core.Id) ]
    [/#if]

    [#switch solution.Engine ]
        [#case "application" ]
            [#local resourceType = AWS_LB_APPLICATION_RESOURCE_TYPE ]
            [#break]

        [#case "network" ]
            [#local resourceType = AWS_LB_NETWORK_RESOURCE_TYPE ]
            [#break]

        [#case "classic" ]
            [#local resourceType = AWS_LB_CLASSIC_RESOURCE_TYPE ]
            [#break]

        [#default]
            [#local resourceType = "COTFatal: Unknown LB Engine" ]
    [/#switch]

    [#assign componentState =
        {
            "Resources" : {
                "lb" : {
                    "Id" : id,
                    "Name" : core.FullName,
                    "ShortName" : core.ShortFullName,
                    "Type" : resourceType,
                    "Monitored" : true
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
[/#macro]

[#macro aws_lbport_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local parentCore = parent.Core ]
    [#local parentSolution = parent.Configuration.Solution ]
    [#local parentState = parent.State ]

    [#local engine = parentSolution.Engine]
    [#local internalFqdn = parentState.Attributes["INTERNAL_FQDN"] ]
    [#local lbId = parentState.Resources["lb"].Id]

    [#-- Check source and destination ports --]
    [#local mapping = solution.Mapping!core.SubComponent.Name ]
    [#local source = (portMappings[mapping].Source)!"" ]
    [#local destination = (portMappings[mapping].Destination)!"" ]
    [#local sourcePort = (ports[source])!{} ]
    [#local destinationPort = (ports[destination])!{} ]

    [#local sourcePortId = sourcePort.Id!source ]
    [#local sourcePortName = sourcePort.Name!source ]

    [#local listenerId = formatResourceId(AWS_ALB_LISTENER_RESOURCE_TYPE, parentCore.Id, source) ]

    [#local targetGroupId = formatResourceId(AWS_ALB_TARGET_GROUP_RESOURCE_TYPE, core.Id) ]
    [#local defaultTargetGroupId = formatResourceId(AWS_ALB_TARGET_GROUP_RESOURCE_TYPE, "default", parentCore.Id, sourcePortId ) ]
    [#local defaultTargetGroupName = formatName("default", parentCore.FullName, sourcePortId )]

    [#local domainRedirectRules = {} ]
    [#if (sourcePort.Certificate)!false ]
        [#local certificateObject = getCertificateObject(solution.Certificate, segmentQualifiers, sourcePortId, sourcePortName ) ]

        [#local hostName = getHostName(certificateObject, occurrence) ]
        [#local primaryDomainObject = getCertificatePrimaryDomain(certificateObject) ]

        [#local fqdn = formatDomainName(hostName, primaryDomainObject) ]
        [#local scheme = "https" ]

        [#-- Redirect any secondary domains --]
        [#list getCertificateSecondaryDomains(certificateObject) as secondaryDomainObject ]
            [#local id = formatResourceId(AWS_ALB_LISTENER_RULE_RESOURCE_TYPE, parentCore.Id, sourcePortId, solution.Priority + secondaryDomainObject?counter) ]
            [#local domainRedirectRules +=
                {
                    id : {
                        "Id" : id,
                        "Priority" : solution.Priority + secondaryDomainObject?counter,
                        "RedirectFrom" : formatDomainName(hostName, secondaryDomainObject),
                        "Type" : AWS_ALB_LISTENER_RULE_RESOURCE_TYPE
                    }
                } ]
        [/#list]
    [#else]
        [#local fqdn = internalFqdn ]
        [#local scheme ="http" ]
    [/#if]

    [#local path = ""]

    [#if solution.Path != "default" ]
        [#if (solution.Path)?ends_with("*") ]
            [#local path = solution.Path?remove_ending("*")?ensure_ends_with("/") ]
        [#else]
            [#local path = solution.Path ]
        [/#if]
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

    [#assign componentState =
        {
            "Resources" : {
                "listener" : {
                    "Id" : listenerId,
                    "Type" : AWS_ALB_LISTENER_RESOURCE_TYPE
                },
                "sg" : {
                    "Id" : formatDependentSecurityGroupId(listenerId),
                    "Name" : formatName(parentCore.FullName, sourcePortId),
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                },
                "listenerRule" : {
                    "Id" : formatResourceId(AWS_ALB_LISTENER_RULE_RESOURCE_TYPE, parentCore.Id, sourcePortId, solution.Priority),
                    "Priority" : solution.Priority,
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
            } +
            attributeIfContent("domainRedirectRules", domainRedirectRules),
            "Attributes" : {
                "LB" : lbId,
                "ENGINE" : engine,
                "FQDN" : fqdn,
                "URL" : url + path,
                "INTERNAL_FQDN" : internalFqdn,
                "INTERNAL_URL" : internalUrl + path,
                "PATH" : path,
                "PORT" : sourcePort.Port,
                "SOURCE_PORT" : sourcePort.Port,
                "DESTINATION_PORT" : destinationPort.Port,
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
[/#macro]
