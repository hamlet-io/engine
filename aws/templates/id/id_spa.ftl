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
                        },
                        {
                            "Names" : "RedirectAliases",
                            "Description" : "Redirect secondary domains to the primary domain name",
                            "Children" : [
                                {
                                    "Names" : "RedirectVersion",
                                    "Type" : STRING_TYPE,
                                    "Default" : "v1"
                                }
                            ]
                        },
                        {
                            "Names" : "EventHandlers",
                            "Description" : "Attach a function to a stage in the Cloudfront Processing",
                            "Subobjects" : true,
                            "Children" : [
                                {
                                    "Names" : "Tier",
                                    "Type" : STRING_TYPE,
                                    "Mandatory" : true
                                },
                                {
                                    "Names" : "Component",
                                    "Type" : STRING_TYPE,
                                    "Mandatory" : true
                                },
                                {
                                    "Names" : "Function",
                                    "Type" : STRING_TYPE,
                                    "Mandatory" : true
                                },
                                {
                                    "Names" : "Instance",
                                    "Type" : STRING_TYPE
                                },
                                {
                                    "Names" : "Version",
                                    "Type" : STRING_TYPE
                                },
                                {
                                    "Names" : "Action",
                                    "Type" : STRING_TYPE,
                                    "Values" : [ "viewer-request", "viewer-response", "origin-request", "origin-response" ],
                                    "Mandatory" : true
                                }
                            ]
                        },
                        {
                            "Names" : "Paths",
                            "Subobjects" : true,
                            "Description" : "Additional path based routes to other components",
                            "Children" : [
                                {
                                    "Names" : "PathPattern",
                                    "Type" : STRING_TYPE,
                                    "Mandatory" : true
                                },
                                {
                                    "Names" : "Link",
                                    "Children" : linkChildrenConfiguration,
                                    "Mandatory" : true
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
                                    "Default" : false
                                }
                            ]
                        }
                    ]
                },
                {
                    "Names" : "Certificate",
                    "Children" : certificateChildConfiguration
                },
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration + [
                        {
                            "Names" : "Security",
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

    [#local cfId  = formatComponentCFDistributionId(core.Tier, core.Component, occurrence)]
    [#local cfName = formatComponentCFDistributionName(core.Tier, core.Component, occurrence)]

    [#if isPresent(solution.Certificate) ]
            [#local certificateObject = getCertificateObject(solution.Certificate!"", segmentQualifiers) ]
            [#local hostName = getHostName(certificateObject, occurrence) ]
            [#local fqdn = formatDomainName(hostName, certificateObject.Domains[0].Name)]
    [#else]
            [#local fqdn = getExistingReference(cfId,DNS_ATTRIBUTE_TYPE)]
    [/#if]

    [#assign pathResources = {}]
    [#list solution.CloudFront.Paths as id,path ]
        [#assign pathResources += {
            id : {
                "cforigin" : {
                    "Id" : id,
                    "Type" : AWS_CLOUDFRONT_ORIGIN_RESOURCE_TYPE
                }
            }
        }]
    [/#list]

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
            } + 
            attributeIfContent( "paths", pathResources ),
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

