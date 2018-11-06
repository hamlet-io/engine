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
                    "Names" : "CloudFront",
                    "Children" : cloudFrontChildConfiguration
                },
                {
                    "Names" : "Certificate",
                    "Children" : certificateChildConfiguration
                },
                {
                    "Names" : "Profiles",
                    "Children" : [
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

    [#local cfUtilities = {}]

    [#if isPresent(solution.Certificate) ]
        [#local certificateObject = getCertificateObject(solution.Certificate!"", segmentQualifiers) ]
        [#local primaryDomainObject = getCertificatePrimaryDomain(certificateObject) ]
        [#local secondaryDomains = getCertificateSecondaryDomains(certificateObject) ]
        [#local hostName = getHostName(certificateObject, occurrence) ]
        [#local fqdn = formatDomainName(hostName, certificateObject.Domains[0].Name)]

        [#if secondaryDomains?has_content && solution.CloudFront.RedirectAliases ]
            [#local utility = "_cfRedirect" ]
            [#local redirectLambdaId = formatLambdaUtilityId(occurrence, utility)  ]
            [#local cfUtilities += {
                    "redirectUtility" : {
                        "Id" : redirectLambdaId,
                        "VersionId" : formatLambdaVersionId(redirectLambdaId)
                        "Name" : formatLambdaUtilityName(occurrence, utility ),
                        "Type" : AWS_LAMBDA_RESOURCE_TYPE,
                        "Utility" : utility
                    }
            }]
        [/#if]
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
            } + 
            attributeIfContent("cfUtilities", cfUtilities),
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

