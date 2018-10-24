[#-- API Gateway --]

[#--
Ideally stages should be a separate subcomponent. However the deployment
model makes that tricky with the swagger definition associated to the api
object.
--]

[#assign apiGatewayDescription = [
"There are multiple modes of deployment offered for the API Gateway, mainly to",
"support use of product domains for endpoints. The key",
"consideration is the handling of the host header. They reflect the",
"changes and improvements AWS have made to the API Gateway over time.",
"For whitelisted APIs, mode 4 is the recommended one now.",
"",
"1) Multi-domain cloudfront + EDGE endpoint",
"    - waf based IP whitelisting",
"    - multiple cloudfront aliases",
"    - host header blocked",
"    - EDGE based API Gateway",
"    - signing based on AWS API domain name",
"    - API-KEY used as shared secret between cloudfront and the API",
"2) Single domain cloudfront + EDGE endpoint",
"    - waf based IP whitelisting",
"    - single cloudfront alias",
"    - host header blocked",
"    - EDGE based API Gateway",
"    - signing based on \"sig4-\" + alias",
"    - API-KEY used as shared secret between cloudfront and the API",
"3) Multi-domain cloudfront + REGIONAL endpoint",
"    - waf based IP whitelisting",
"    - multiple cloudfront aliases",
"    - host header passed through to endpoint",
"    - REGIONAL based API Gateway",
"   - signing based on any of the aliases",
"    - API-KEY used as shared secret between cloudfront and the API",
"4) API endpoint",
"    - policy based IP whitelisting",
"    - multiple aliases",
"    - EDGE or REGIONAL",
"   - signing based on any of the aliases",
"    - API-KEY can be used for client metering",
"",
"If multiple domains are provided, the primary domain is used to provide the",
"endpoint for the the API documentation and for the gateway attributes. For",
"documentation, the others used to redirect to the primary."
] ]


[#-- Resources --]
[#assign AWS_APIGATEWAY_RESOURCE_TYPE = "apigateway"]
[#assign AWS_APIGATEWAY_DEPLOY_RESOURCE_TYPE = "apiDeploy"]
[#assign AWS_APIGATEWAY_STAGE_RESOURCE_TYPE = "apiStage"]
[#assign AWS_APIGATEWAY_DOMAIN_RESOURCE_TYPE = "apiDomain"]
[#assign AWS_APIGATEWAY_AUTHORIZER_RESOURCE_TYPE = "apiAuthorizer"]
[#assign AWS_APIGATEWAY_BASEPATHMAPPING_RESOURCE_TYPE = "apiBasePathMapping"]
[#assign AWS_APIGATEWAY_USAGEPLAN_RESOURCE_TYPE = "apiUsagePlan"]
[#assign AWS_APIGATEWAY_APIKEY_RESOURCE_TYPE = "apiKey"]
[#assign AWS_APIGATEWAY_USAGEPLAN_MEMBER_RESOURCE_TYPE = "apiUsagePlanMember"]

[#function formatDependentAPIGatewayAuthorizerId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_APIGATEWAY_AUTHORIZER_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatDependentAPIGatewayAPIKeyId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_APIGATEWAY_APIKEY_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#-- Components --]
[#assign APIGATEWAY_COMPONENT_TYPE = "apigateway"]
[#assign APIGATEWAY_USAGEPLAN_COMPONENT_TYPE = "apiusageplan"]
[#assign APIGATEWAY_COMPONENT_DOCS_EXTENSION = "docs"]

[#assign componentConfiguration +=
    {
        APIGATEWAY_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" :
                        [
                            "Application level API proxy",
                            ""
                        ] + apiGatewayDescription
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
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "WAF",
                    "Children" : wafChildConfiguration
                },
                {
                    "Names" : "EndpointType",
                    "Type" : STRING_TYPE,
                    "Values" : ["EDGE", "REGIONAL"],
                    "Default" : "EDGE"
                },
                {
                    "Names" : "IPAddressGroups",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Authentication",
                    "Type" : STRING_TYPE,
                    "Values" : ["IP", "SIG4ORIP", "SIG4ANDIP"],
                    "Default" : "IP"
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
                            "Names" : "CustomHeaders",
                            "Type" : ARRAY_OF_ANY_TYPE,
                            "Default" : []
                        },
                        {
                            "Names" : "Mapping",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
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
                    "Children" : certificateChildConfiguration
                },
                {
                    "Names" : "Publish",
                    "Children" : [
                        {
                            "Names" : "DnsNamePrefix",
                            "Type" : STRING_TYPE,
                            "Default" : "docs"
                        },
                        {
                            "Names" : "IPAddressGroups",
                            "Type" : ARRAY_OF_STRING_TYPE,
                            "Default" : []
                        }
                    ]
                },
                {
                    "Names" : "Mapping",
                    "Children" : [
                        {
                            "Names" : "IncludeStage",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        }
                    ]
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
        },
        APIGATEWAY_USAGEPLAN_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "provides a metered link between an API gateway and an invoking client"
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
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
        }
    }]

[#function getAPIGatewayState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#-- Resource Id doesn't follow the resource type for backwards compatability --]
    [#if getExistingReference(formatResourceId("api", core.Id))?has_content ]
        [#local apiId = formatResourceId("api", core.Id)]
    [#else ]
        [#local apiId = formatResourceId(AWS_APIGATEWAY_RESOURCE_TYPE, core.Id)]
    [/#if]
    [#local apiName = formatComponentFullName(core.Tier, core.Component, occurrence)]

    [#local stageId = formatResourceId(AWS_APIGATEWAY_STAGE_RESOURCE_TYPE, core.Id)]
    [#local stageName = core.Version.Name]

    [#local serviceName = "execute-api" ]

    [#local certificatePresent = isPresent(solution.Certificate) ]
    [#local cfPresent          = isPresent(solution.CloudFront) ]
    [#local wafPresent         = isPresent(solution.WAF) ]
    [#local mappingPresent     = isPresent(solution.Mapping) &&
                                     (!cfPresent || solution.CloudFront.Mapping) ]
    [#local publishPresent     = isPresent(solution.Publish) ]

    [#local endpointType       = solution.EndpointType ]
    [#local isEdgeEndpointType = solution.EndpointType == "EDGE" ]

    [#local internalFqdn =
        formatDomainName(
            getExistingReference(apiId),
            serviceName,
            regionId,
            "amazonaws.com") ]

    [#local fqdn = internalFqdn]
    [#local signingFqdn = internalFqdn]
    [#local mappingStage = ""]
    [#local internalPath = ""]
    [#local stagePath = "/" + stageName]
    [#local certificateId = "" ]

    [#-- Effective API Gateway end points --]
    [#local hostDomains = [] ]
    [#local hostName = "" ]

    [#-- Custom domain definitions needed for signing --]
    [#local customDomains = [] ]
    [#local customHostName = "" ]

    [#-- Documentation domains --]
    [#local docsDomains = [] ]
    [#local docsHostName = "" ]

    [#if certificatePresent ]
        [#local certificateObject = getCertificateObject(solution.Certificate!"", segmentQualifiers)]
        [#local certificateDomains = getCertificateDomains(certificateObject) ]
        [#local primaryDomainObject = getCertificatePrimaryDomain(certificateObject) ]
        [#local hostName = getHostName(certificateObject, occurrence) ]
        [#local docsHostName = hostName ]
        [#local certificateId = formatDomainCertificateId(certificateObject, hostName) ]

        [#if mappingPresent ]
            [#-- Mode 2, 3, 4 --]
            [#local fqdn = formatDomainName(hostName, primaryDomainObject)]
            [#local hostDomains = certificateDomains ]
            [#local customDomains = hostDomains ]
            [#local customHostName = hostName ]
            [#local docsDomains = hostDomains ]
            [#local signingFqdn = fqdn]
            [#if solution.Mapping.IncludeStage]
                [#local mappingStage = stageName ]
                [#local stagePath = "" ]
            [#else]
                [#local internalPath = "/" + stageName ]
            [/#if]

            [#if cfPresent && isEdgeEndpointType]
                [#-- Mode 2 --]
                [#local hostDomains = [primaryDomainObject] ]
                [#local customDomains = hostDomains ]
                [#local customHostName = formatName("sig4", hostName) ]
                [#local signingFqdn = formatDomainName(customHostName, primaryDomainObject) ]
            [/#if]
        [#else]
            [#if cfPresent ]
                [#-- Mode 1 --]
                [#local fqdn = formatDomainName(hostName, primaryDomainObject) ]
                [#local hostDomains = certificateDomains ]
                [#local docsDomains = hostDomains ]
            [/#if]
        [/#if]
    [/#if]

    [#-- Determine the list of hostname alternatives --]
    [#local fqdns = [] ]
    [#list hostDomains as domain]
        [#local fqdns += [ formatDomainName(hostName, domain.Name) ] ]
    [/#list]

    [#-- Cloudfront resources if required --]
    [#local cfResources = {} ]
    [#if cfPresent]
        [#local cfId = formatDependentCFDistributionId(apiId)]
        [#local cfResources =
            {
                "distribution" : {
                    "Id" : cfId,
                    "Name" : formatComponentCFDistributionName(core.Tier, core.Component, occurrence),
                    "Type" : AWS_CLOUDFRONT_DISTRIBUTION_RESOURCE_TYPE
                } +
                valueIfContent(
                    {
                        "CertificateId" : certificateId,
                        "Fqdns" : fqdns
                    },
                    fqdns
                ),
                "origin" : {
                    "Id" : "apigateway",
                    "Fqdn" : signingFqdn,
                    "Type" : AWS_CLOUDFRONT_ORIGIN_RESOURCE_TYPE
                },
                "usageplan" : {
                    "Id" : formatDependentResourceId(AWS_APIGATEWAY_USAGEPLAN_RESOURCE_TYPE, cfId),
                    "Name" : formatComponentFullName(core.Tier, core.Component, occurrence),
                    "Type" : AWS_APIGATEWAY_USAGEPLAN_RESOURCE_TYPE
                }
            } +
            attributeIfTrue(
                "wafacl",
                wafPresent,
                {
                    "Id" : formatDependentWAFAclId(apiId),
                    "Name" : formatComponentWAFAclName(core.Tier, core.Component, occurrence),
                    "Type" : AWS_WAF_ACL_RESOURCE_TYPE
                }
            ) ]
    [/#if]

    [#-- Custom domain resources if required --]
    [#local customDomainResources = {} ]
    [#list customDomains as domain]
        [#local customFqdn = formatDomainName(customHostName, domain) ]
        [#local customFqdnParts = splitDomainName(customFqdn) ]
        [#local customFqdnId = formatResourceId(AWS_APIGATEWAY_DOMAIN_RESOURCE_TYPE, customFqdnParts) ]
        [#local customDomainResources +=
            {
                customFqdn : {
                    "domain" : {
                        "Id" : customFqdnId,
                        "Name" : customFqdn,
                        "CertificateId" : certificateId,
                        "Type" : AWS_APIGATEWAY_DOMAIN_RESOURCE_TYPE
                    },
                    "basepathmapping" : {
                        "Id" : formatDependentResourceId(AWS_APIGATEWAY_BASEPATHMAPPING_RESOURCE_TYPE, customFqdnId),
                        "Stage" : mappingStage,
                        "Type" : AWS_APIGATEWAY_BASEPATHMAPPING_RESOURCE_TYPE
                    }
                }
            } ]
    [/#list]

    [#-- API documentation if required --]
    [#local docsResources = {} ]
    [#local docsPrimaryFqdn = "" ]
    [#if publishPresent]
        [#local docsPrimaryFqdn =
            formatDomainName(
                solution.Publish.DnsNamePrefix,
                docsHostName,
                primaryDomainObject) ]
        [#list docsDomains as domain]
            [#local docsFqdn =
                formatDomainName(
                    solution.Publish.DnsNamePrefix,
                    docsHostName,
                    domain) ]

            [#local docsFqdnParts = splitDomainName(docsFqdn) ]
            [#local docsId = formatS3Id(docsFqdnParts) ]

            [#local redirectTo =
                valueIfTrue(
                    docsPrimaryFqdn,
                    isSecondaryDomain(domain),
                    ""
                ) ]
            [#local docsResources +=
                {
                    docsFqdn : {
                        "bucket" : {
                            "Id" : docsId,
                            "Name" : docsFqdn,
                            "Type" : AWS_S3_RESOURCE_TYPE,
                            "RedirectTo" : redirectTo
                        },
                        "policy" : {
                            "Id" : formatBucketPolicyId(docsFqdnParts),
                            "Type" : AWS_S3_BUCKET_POLICY_RESOURCE_TYPE
                        }
                    }
                } ]
         [/#list]
    [/#if]

    [#return
        {
            "Resources" : {
                "apigateway" : {
                    "Id" : apiId,
                    "Name" : apiName,
                    "Type" : AWS_APIGATEWAY_RESOURCE_TYPE
                },
                "apideploy" : {
                    "Id" : formatResourceId(AWS_APIGATEWAY_DEPLOY_RESOURCE_TYPE, core.Id, runId),
                    "Type" : AWS_APIGATEWAY_DEPLOY_RESOURCE_TYPE
                },
                "apistage" : {
                    "Id" : stageId,
                    "Name" : stageName,
                    "Type" : AWS_APIGATEWAY_STAGE_RESOURCE_TYPE
                },
                "lg" : {
                    "Id" : formatDependentLogGroupId(stageId),
                    "Name" : {
                        "Fn::Join" : [
                            "",
                            [
                                "API-Gateway-Execution-Logs_",
                                getExistingReference(apiId),
                                "/",
                                stageName
                            ]
                        ]
                    },
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                },
                "accesslg" : {
                    "Id" : formatDependentLogGroupId(stageId, "access"),
                    "Name" : formatAbsolutePath(core.FullAbsolutePath, "access"),
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                }
            } +
            attributeIfContent("cf", cfResources) +
            attributeIfContent("docs", docsResources) +
            attributeIfContent("customDomains", customDomainResources),
            "Attributes" : {
                "FQDN" : fqdn,
                "URL" : "https://" + fqdn + stagePath,
                "SCHEME" : "https",
                "BASE_PATH" : stagePath,
                "SIGNING_SERVICE_NAME" : serviceName,
                "SIGNING_FQDN" : signingFqdn,
                "INTERNAL_FQDN" : internalFqdn,
                "INTERNAL_URL" : "https://" + internalFqdn + stagePath,
                "INTERNAL_PATH" : internalPath
            } +
            attributeIfTrue(
                "DOCS_URL",
                docsPrimaryFqdn != "",
                "http://" + docsPrimaryFqdn
            ),
            "Roles" : {
                "Inbound" : {
                    "default" : "invoke",
                    "invoke" : {
                        "Principal" : "apigateway.amazonaws.com",
                        "SourceArn" : formatInvokeApiGatewayArn(apiId, stageName)
                    }
                },
                "Outbound" : {
                    "default" : "invoke",
                    "invoke" : apigatewayInvokePermission(apiId, stageName)
                }
            }
        }
    ]
[/#function]

[#function getAPIGatewayUsagePlanState occurrence]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local outboundPolicy = [] ]

    [#list solution.Links?values as link]
        [#if link?is_hash]
            [#assign linkTarget = getLinkTarget(occurrence, link) ]

            [@cfDebug listMode linkTarget false /]

            [#if !linkTarget?has_content]
                [#continue]
            [/#if]
            [#local linkTargetCore = linkTarget.Core ]
            [#local linkTargetRoles = linkTarget.State.Roles ]

            [#if !(linkTarget.Configuration.Solution.Enabled!true) ]
                [#continue]
            [/#if]

            [#switch linkTargetCore.Type]
                [#case APIGATEWAY_COMPONENT_TYPE ]
                    [#local outboundPolicy += linkTargetRoles.Outbound["invoke"] ]
                    [#break]
            [/#switch]
        [/#if]
    [/#list]

    [#return
        {
            "Resources" : {
                "apiusageplan" : {
                    "Id" : formatResourceId(AWS_APIGATEWAY_USAGEPLAN_RESOURCE_TYPE, core.Id),
                    "Name" : core.FullName,
                    "Type" : AWS_APIGATEWAY_USAGEPLAN_RESOURCE_TYPE
                }
            },
            "Attributes" : {
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {
                    "default" : "invoke",
                    "invoke" : outboundPolicy
                }
            }
        }
    ]
[/#function]
