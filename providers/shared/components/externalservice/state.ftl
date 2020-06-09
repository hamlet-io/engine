[#ftl]

[#macro shared_externalservice_default_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local attributes = {}]
    [#if solution.Properties?has_content ]
        [#list solution.Properties?values as property ]
            [#local attributes += { property.Key?upper_case, property.Value }]
        [/#list]
    [/#if]

    [#local fragment = getOccurrenceFragmentBase(occurrence) ]
    [#local contextLinks = getLinkTargets(occurrence) ]
    [#assign _context =
        {
            "Id" : fragment,
            "Name" : fragment,
            "Instance" : core.Instance.Id,
            "Version" : core.Version.Id,
            "DefaultEnvironment" : defaultEnvironment(occurrence, {}, {}),
            "Environment" : {},
            "Links" : contextLinks,
            "BaselineLinks" : {},
            "DefaultCoreVariables" : false,
            "DefaultEnvironmentVariables" : true,
            "DefaultBaselineVariables" : false,
            "DefaultLinkVariables" : false
        }
    ]

    [#-- Add in fragment specifics including override of defaults --]
    [#if solution.Fragment?has_content ]
        [#local fragmentId = formatFragmentId(_context)]
        [#include fragmentList?ensure_starts_with("/")]
    [/#if]

    [#local environment = getFinalEnvironment(occurrence, _context ).Environment ]

    [#list environment as name,value]
        [#local attributes += { name : value } ]
    [/#list]

    [#assign componentState =
        {
            "Resources" : {
                "external" : {
                    "Id" : formatResourceId(SHARED_EXTERNAL_RESOURCE_TYPE, core.Id),
                    "Type" : SHARED_EXTERNAL_RESOURCE_TYPE,
                    "Deployed" : true
                }
            },
            "Attributes" : attributes,
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]

[#macro shared_externalserviceendpoint_default_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local cidrs = getGroupCIDRs(solution.IPAddressGroups, true, occurrence)]
    [#local hostIPs = []]
    [#list cidrs as cidr ]
        [#local hostIPs = combineEntities(hostIPs, getHostsFromNetwork(cidr), UNIQUE_COMBINE_BEHAVIOUR) ]
    [/#list]

    [#local port = ports[solution.Port]]

    [#local parentAttributes = parent.State.Attributes ]

    [#assign componentState =
        {
            "Resources" : {
                "externalEndpoint" : {
                    "Id" : formatId(SHARED_EXTERNAL_RESOURCE_TYPE, core.Id),
                    "Name" : core.FullName,
                    "Type" : SHARED_EXTERNAL_RESOURCE_TYPE,
                    "Deployed" : true
                }
            },
            "Attributes" : parentAttributes +
            {
                "IP" : hostIPs?join(","),
                "PORT" : port.Port,
                "PROTOCOL" : port.Protocol
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]
