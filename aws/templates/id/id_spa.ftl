[#-- SPA --]

[#-- Components --]
[#assign SPA_COMPONENT_TYPE = "spa"]

[#assign componentConfiguration +=
    {
        SPA_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "Object stored hosted web application with content distribution management"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "application"
                }
            ],
            "Attributes" : [
                {
                    "Names" : ["Fragment", "Container"],
                    "Type" : STRING_TYPE,
                    "Default" : ""
                },
                {
                    "Names" : "Links",
                    "Type" : OBJECT_TYPE,
                    "Default" : {}
                },
                {
                    "Names" : "WAF",
                    "Children" : wafChildConfiguration
                },
                {
                    "Names" : "CloudFront",
                    "Children" : [
                        {
                            "Names" : "AssumeSNI",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "EnableLogging",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "CountryGroups",
                            "Type" : ARRAY_OF_STRING_TYPE,
                            "Default" : []
                        },
                        {
                            "Names" : "ErrorPage",
                            "Type" : STRING_TYPE,
                            "Default" : "/index.html"
                        },
                        {
                            "Names" : "DeniedPage",
                            "Type" : STRING_TYPE,
                            "Default" : ""
                        },
                        {
                            "Names" : "NotFoundPage",
                            "Type" : STRING_TYPE,
                            "Default" : ""
                        },
                        {
                            "Names" : "CachingTTL",
                            "Children" : [
                                {
                                    "Names" : "Default",
                                    "Type" : NUMBER_TYPE,
                                    "Default" : 600
                                },
                                {
                                    "Names" : "Maximum",
                                    "Type" : NUMBER_TYPE,
                                    "Default" : 31536000
                                },
                                {
                                    "Names" : "Minimum",
                                    "Type" : NUMBER_TYPE,
                                    "Default" : 0
                                }
                            ]
                        },
                        {
                            "Names" : "Compress",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        }
                    ]
                },
                {
                    "Names" : "Certificate",
                    "Children" : [
                        {
                            "Names" : "*"
                        }
                    ]
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
                }
            ]
        }
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

