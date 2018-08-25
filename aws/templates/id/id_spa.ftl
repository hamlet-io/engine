[#-- SPA --]

[#-- Components --]
[#assign SPA_COMPONENT_TYPE = "spa"]

[#assign componentConfiguration +=
    {
        SPA_COMPONENT_TYPE : [
            {
                "Name" : ["Fragment", "Container"],
                "Default" : ""
            },
            {
                "Name" : "Links",
                "Default" : {}
            },
            {
                "Name" : "WAF",
                "Children" : wafChildConfiguration
            },
            {
                "Name" : "CloudFront",
                "Children" : [
                    {
                        "Name" : "AssumeSNI",
                        "Default" : true
                    },
                    {
                        "Name" : "EnableLogging",
                        "Default" : true
                    },
                    {
                        "Name" : "CountryGroups",
                        "Default" : []
                    },
                    {
                        "Name" : "ErrorPage",
                        "Default" : "/index.html"
                    },
                    {
                        "Name" : "DeniedPage",
                        "Default" : ""
                    },
                    {
                        "Name" : "NotFoundPage",
                        "Default" : ""
                    },
                    {
                        "Name" : "CachingTTL",
                        "Children" : [
                            {
                                "Name" : "Default",
                                "Default" : 600
                            },
                            {
                                "Name" : "Maximum",
                                "Default" : 31536000
                            },
                            {
                                "Name" : "Minimum",
                                "Default" : 0
                            }
                        ]
                    },
                    {
                        "Name" : "Compress",
                        "Default" : true
                    }
                ]
            },
            {
                "Name" : "Certificate",
                "Children" : [
                    {
                        "Name" : "*"
                    }
                ]
            }
        ]
    }]
    
[#function getSPAState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#assign cfId  = formatComponentCFDistributionId(core.Tier, core.Component, occurrence)]
    [#assign cfName = formatComponentCFDistributionName(core.Tier, core.Component, occurrence)]

    [#if solution.Certificate.Configured && solution.Certificate.Enabled ]
            [#local certificateObject = getCertificateObject(solution.Certificate!"", segmentQualifiers) ]
            [#local hostName = getHostName(certificateObject, occurrence) ]
            [#local fqdn = formatDomainName(hostName, certificateObject.Domain.Name)]
    [#else]
            [#local fqdn = getExistingReference(cfId,DNS_ATTRIBUTE_TYPE)]
    [/#if]

    [#return
        {
            "Resources" : {
                "cf" : {
                    "Id" : cfId,
                    "Name" : cfName,
                    "Type" : AWS_CLOUDFRONT_DISTRIBUTION_RESOURCE_TYPE
                },
                "cforiginspa" : {
                    "Id" : "spa",
                    "Type" : AWS_CLOUDFRONT_ORIGIN_RESOURCE_TYPE
                },
                "cforiginconfig" : { 
                    "Id" : "config",
                    "Type" : AWS_CLOUDFRONT_ORIGIN_RESOURCE_TYPE
                },
                "wafacl" : { 
                    "Id" : formatDependentWAFAclId(cfId),
                    "Name" : formatComponentWAFAclName(core.Tier, core.Component, occurrence),
                    "Type" : AWS_WAF_ACL_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "FQDN" : fqdn,
                "URL" : "https://" + fqdn
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]

