[#ftl]
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
adjust routes within http frameworks. The "basePath" attribute in any openAPI
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

[#macro aws_apigateway_cf_state occurrence parent={} ]
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
    [#local stageName = valueIfContent(
                            core.Version.Name,
                            core.Version.Name,
                            valueIfContent(
                                core.Instance.Name,
                                core.Instance.Name,
                                core.Name
                            ))]

    [#local serviceName = "execute-api" ]

    [#local certificatePresent = isPresent(solution.Certificate) ]
    [#local cfPresent          = isPresent(solution.CloudFront) ]
    [#local wafPresent         = isPresent(solution.WAF) ]
    [#local mappingPresent     = isPresent(solution.Mapping) &&
                                     (!cfPresent || solution.CloudFront.Mapping) ]
    [#local publishPresent     = isPresent(solution.Publish) ]

    [#local endpointType       = solution.EndpointType ]
    [#local isEdgeEndpointType = solution.EndpointType == "EDGE" ]

    [#local region = contentIfContent(
                        getExistingReference(apiId, REGION_ATTRIBUTE_TYPE),
                        regionId
                    )]
    [#-- The AWS assigned domain for the API --]
    [#local internalFqdn =
        formatDomainName(
            getExistingReference(apiId),
            serviceName,
            region,
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

    [#local lgId = formatDependentLogGroupId(stageId) ]
    [#local lgName = {
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

    [#local accessLgId = formatDependentLogGroupId(stageId, "access") ]
    [#local accessLgName = formatAbsolutePath(core.FullAbsolutePath, "access")]

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

    [#assign componentState =
        {
            "Resources" : {
                "apigateway" : {
                    "Id" : apiId,
                    "Name" : apiName,
                    "Type" : AWS_APIGATEWAY_RESOURCE_TYPE,
                    "Monitored" : true
                },
                "apideploy" : {
                    "Id" : formatResourceId(AWS_APIGATEWAY_DEPLOY_RESOURCE_TYPE, core.Id, commandLineOptions.Run.Id),
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
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
                },
                "accesslg" : {
                    "Id" : accessLgId,
                    "Name" : accessLgName,
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
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
[/#macro]
