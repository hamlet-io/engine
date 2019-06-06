[#-- API Gateway --]

[#--
Ideally stages should be a separate subcomponent. However the deployment
model makes that tricky with the swagger definition associated to the api
object.
--]

[#assign apiGatewayDescription = [
"There are multiple modes of deployment offered for the API Gateway, mainly to",
"support use of product domains for endpoints. The key",
"consideration is the handling of the host header. The modes reflect the",
"changes and improvements AWS have made to the API Gateway over time.",
"For whitelisted APIs, mode 4 is the recommended one now.",
"\n",
"1. Multi-domain cloudfront + EDGE endpoint",
"    - waf based IP whitelisting",
"    - multiple cloudfront aliases",
"    - host header blocked",
"    - EDGE based API Gateway",
"    - signing based on AWS assigned API domain name",
"    - API-KEY used as shared secret between cloudfront and the API",
"2. Single domain cloudfront + EDGE endpoint",
"    - waf based IP whitelisting",
"    - single cloudfront alias",
"    - host header blocked",
"    - EDGE based API Gateway",
"    - signing based on \"sig4-\" + alias",
"    - API-KEY used as shared secret between cloudfront and the API",
"3. Multi-domain cloudfront + REGIONAL endpoint",
"    - waf based IP whitelisting",
"    - multiple cloudfront aliases",
"    - host header passed through to endpoint",
"    - REGIONAL based API Gateway",
"    - signing based on any of the aliases",
"    - API-KEY used as shared secret between cloudfront and the API",
"4. API endpoint",
"    - waf or policy based IP whitelisting",
"    - multiple aliases or AWS assigned domain",
"    - EDGE or REGIONAL",
"    - signing based on any of the aliases",
"    - API-KEY can be used for client metering",
"\n",
"If multiple domains are provided, the primary domain is used to provide the",
"endpoint for the the API documentation and for the gateway attributes. For",
"documentation, the others redirect to the primary."
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
                    "Description" : "Deprecated - Please switch to the publishers configuration",
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
                    "Names" : "Publishers",
                    "Subobjects" : true,
                    "Children" : [
                        {
                            "Names" : "Links",
                            "Subobjects" : true,
                            "Children" : linkChildrenConfiguration
                        },
                        {
                            "Names" : "Path",
                            "Children" : pathChildConfiguration
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
                    "Children" : profileChildConfiguration + [
                        {
                            "Names" : "Security",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
                },
                {
                    "Names" : "Alerts",
                    "Subobjects" : true,
                    "Children" : alertChildrenConfiguration
                },
                {
                    "Names" : "LogMetrics",
                    "Subobjects" : true,
                    "Children" : logMetricChildrenConfiguration
                },
                {
                    "Names" : "BasePathBehaviour",
                    "Description" : "How to handle base paths provided in the spec",
                    "Type" : STRING_TYPE,
                    "Values" : [ "ignore", "prepend", "split" ],
                    "Default" : "ignore"
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

[#--
The config can get confusing as there are a lot of knobs to fiddle with. A few
notes:-

A certificate attribute needs to be defined to have any custom domains used on
either CloudFront or the API Gateway. If it isn't present, then only the Amazon
provided domains will be available.

IPAddressGroups on the gateway itself control IP checks in the resource policy.
The Authentication configuration also affects the resource policy.

IPAddressGroups on WAF control what IPs are checked by WAF.

At least one of the IPAddressGroups above must be defined, even if it is just
to include the _global group. Basically acess must be explicitly stated even if
access to everyone is desired.

IPAddressGroups on Publish control what IPs can access the online documentation

Mapping on gateway itself controls whether API domain mappings are created and
whether the stage is included in the mappings.

Mapping on CloudFront overrides the mapping on the gateway itself in terms of
whether mappings are created, but it still relies on the gateway setting for
whether the stage should be included in the mapping. Thus using mappings with
CloudFront requires a Mapping attribute to be defined on the API Gateway AND
on CloudFront.

WAF will be attached to CloudFront if present and to the API Gateway otherwise.

The inclusion of the stage at the start of the API URL path and in the path as
seen by backing lambda code varies depending on the use of domain mappings.

If no domain mappings are employed, the stage should be in the API URL
but will not appear in the path seen by lambda - it is effectively "consumed"
working out which stage to call. If a domain mapping is employed, then the stage
will not appear in the API URL or the lambda path if it is included in the mapping.
Equally, the stage will appear in the API URL and the lambda path if it not
included in the mapping. (Confusing isn't it :-) )

The INTERNAL_PATH is provided to inform the lambda code what it will see of the
stage in the path it receives. This environment variable can thus be used to
adjust routes within http frameworks. The "basePath" attribute in any swagger
spec should reflect what is expected in the API URL as described above.

To obtain the modes described above, the following key configuration setting
combinations should be used;

Mode 1: CloudFront(Mapping=false)
Mode 2: CloudFront(Mapping=true)  Mapping EndpointType=EDGE
Mode 3: CloudFront(Mapping=true)  Mapping EndpointType=REGIONAL
Mode 4: Mapping

If Certificate is not configured, then Mode 1 is used if CloudFront is
configured and Mode 4 is used if CloudFront is not configured. No mappings are
created in either case.
--]

[#macro aws_apigateway_cf_state occurrence parent={} baseState={}  ]
    [#assign componentState = getAPIGatewayState(occurrence)]
[/#macro]

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

    [#-- The AWS assigned domain for the API --]
    [#local internalFqdn =
        formatDomainName(
            getExistingReference(apiId),
            serviceName,
            regionId,
            "amazonaws.com") ]

    [#-- Preferred domain to use when accessing the API --]
    [#-- Uses the preferred domain where more than one are defined --]
    [#local fqdn = internalFqdn]

    [#-- Domain to be used in SIG4 calculations --]
    [#-- Also used for origin endpoint for CloudFront --]
    [#local signingFqdn = internalFqdn]

    [#-- Stage to be used in domain mappings --]
    [#local mappingStage = ""]

    [#-- What the lambda code sees as far as the stage in the path is concerned --]
    [#local internalPath = ""]

    [#-- How the stage should be included in the API URL --]
    [#local stagePath = "/" + stageName]

    [#local certificateId = "" ]

    [#assign lgId = formatDependentLogGroupId(stageId) ]
    [#assign lgName = {
                        "Fn::Join" : [
                            "",
                            [
                                "API-Gateway-Execution-Logs_",
                                getExistingReference(apiId),
                                "/",
                                stageName
                            ]
                        ]
                    }]

    [#assign accessLgId = formatDependentLogGroupId(stageId, "access") ]
    [#assign accessLgName = formatAbsolutePath(core.FullAbsolutePath, "access")]

    [#local logMetrics = {} ]
    [#list solution.LogMetrics as name,logMetric ]
        [#local logMetrics += {
            "lgMetric" + name : {
                "Id" : formatDependentLogMetricId( lgId, logMetric.Id ),
                "Name" : getMetricName( logMetric.Name, AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE, core.ShortFullName ),
                "Type" : AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE,
                "LogGroupName" : lgName,
                "LogGroupId" : lgId,
                "LogFilter" : logMetric.LogFilter
            },
            "lgMetric" + name + "access" : {
                "Id" : formatDependentLogMetricId( accessLgId, logMetric.Id ),
                "Name" : getMetricName( logMetric.Name, AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE, core.ShortFullName ),
                "Type" : AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE,
                "LogGroupName" : accessLgName,
                "LogGroupId" : accessLgId,
                "LogFilter" : logMetric.LogFilter
            }
        }]
    [/#list]

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

    [#-- CloudFront resources if required --]
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
            } ]
    [/#if]
    [#local wafResources = {} ]
    [#if wafPresent]
        [#local wafResources =
            {
                "acl" : {
                    "Id" : formatDependentWAFAclId(apiId),
                    "Name" : formatComponentWAFAclName(core.Tier, core.Component, occurrence),
                    "Type" : AWS_WAF_ACL_RESOURCE_TYPE
                },
                "association" : {
                    "Id" : formatDependentWAFAclAssociationId(apiId),
                    "Type" : AWS_WAF_ACL_ASSOCIATION_RESOURCE_TYPE
                }
            } ]
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
    [#-- API Docs have been deprecated this is being kept to remove the old s3 buckets --]
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

            [#local docsResources +=
                {
                    docsFqdn : {
                        "bucket" : {
                            "Id" : docsId,
                            "Name" : docsFqdn,
                            "Type" : AWS_S3_RESOURCE_TYPE
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
                    "Type" : AWS_APIGATEWAY_RESOURCE_TYPE,
                    "Monitored" : true
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
                    "Id" : lgId,
                    "Name" : lgName,
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                },
                "accesslg" : {
                    "Id" : accessLgId,
                    "Name" : accessLgName,
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                }
            } +
            attributeIfContent("logMetrics", logMetrics) +
            attributeIfContent("cf", cfResources) +
            attributeIfContent("wafacl", wafResources) +
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

[#macro aws_apiusageplan_cf_state occurrence parent={} baseState={}  ]
    [#assign componentState = getAPIGatewayUsagePlanState(occurrence)]
[/#macro]

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
