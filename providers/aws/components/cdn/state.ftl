[#ftl]

[#macro aws_cdn_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local cfId  = formatResourceId(AWS_CLOUDFRONT_DISTRIBUTION_RESOURCE_TYPE, core.Id)]
    [#local cfName = core.FullName]

    [#if isPresent(solution.Certificate) ]
        [#local certificateObject = getCertificateObject(solution.Certificate!"", segmentQualifiers) ]
        [#local hostName = getHostName(certificateObject, occurrence) ]
        [#local primaryDomainObject = getCertificatePrimaryDomain(certificateObject) ]
        [#local fqdn = formatDomainName(hostName, primaryDomainObject)]

    [#else]
            [#local fqdn = getExistingReference(cfId,DNS_ATTRIBUTE_TYPE)]
    [/#if]

    [#assign componentState =
        {
            "Resources" : {
                "cf" : {
                    "Id" : cfId,
                    "Name" : cfName,
                    "Type" : AWS_CLOUDFRONT_DISTRIBUTION_RESOURCE_TYPE
                },
                "wafacl" : {
                    "Id" : formatDependentWAFAclId(cfId),
                    "Name" : formatComponentWAFAclName(core.Tier, core.Component, occurrence),
                    "Type" : AWS_WAF_ACL_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "FQDN" : fqdn,
                "URL" : "https://" + fqdn,
                "DISTRIBUTION_ID" : getExistingReference(cfId)
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]


[#macro aws_cdnroute_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local parentAttributes = parent.State.Attributes ]
    [#local parentResources = parent.State.Resources ]

    [#local cfId = parentResources["cf"].Id ]

    [#local pathPattern = solution.PathPattern ]
    [#local isDefaultPath = false ]
    [#switch pathPattern?lower_case ]
        [#case "" ]
        [#case "_default"]
        [#case "/"]
            [#local isDefaultPath = true ]
            [#local pathPattern = "/*" ]
    [/#switch]

    [#assign componentState =
        {
            "Resources" : {
                "origin" : {
                    "Id" : formatResourceId(AWS_CLOUDFRONT_ORIGIN_RESOURCE_TYPE, core.Id ),
                    "Type" : AWS_CLOUDFRONT_ORIGIN_RESOURCE_TYPE,
                    "Deployed" : getExistingReference(cfId)?has_content,
                    "PathPattern" : pathPattern,
                    "DefaultPath" : isDefaultPath
                }
            },
            "Attributes" : parentAttributes + {
                "URL" : formatAbsolutePath( parentAttributes["URL"], pathPattern?remove_ending("*") )
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]