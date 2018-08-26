[#-- SPA --]

[#-- Components --]
[#assign SPA_COMPONENT_TYPE = "spa"]

[#assign componentConfiguration +=
    {
        SPA_COMPONENT_TYPE : [
            {
                "Name" : ["Fragment", "Container"],
                "Type" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Name" : "Links",
                "Type" : OBJECT_TYPE,
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
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Name" : "EnableLogging",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Name" : "CountryGroups",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Default" : []
                    },
                    {
                        "Name" : "ErrorPage",
                        "Type" : STRING_TYPE,
                        "Default" : "/index.html"
                    },
                    {
                        "Name" : "DeniedPage",
                        "Type" : STRING_TYPE,
                        "Default" : ""
                    },
                    {
                        "Name" : "NotFoundPage",
                        "Type" : STRING_TYPE,
                        "Default" : ""
                    },
                    {
                        "Name" : "CachingTTL",
                        "Children" : [
                            {
                                "Name" : "Default",
                                "Type" : NUMBER_TYPE,
                                "Default" : 600
                            },
                            {
                                "Name" : "Maximum",
                                "Type" : NUMBER_TYPE,
                                "Default" : 31536000
                            },
                            {
                                "Name" : "Minimum",
                                "Type" : NUMBER_TYPE,
                                "Default" : 0
                            }
                        ]
                    },
                    {
                        "Name" : "Compress",
                        "Type" : BOOLEAN_TYPE,
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

