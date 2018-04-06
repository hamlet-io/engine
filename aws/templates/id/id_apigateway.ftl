[#-- API Gateway --]

[#-- Resources --]
[#assign AWS_APIGATEWAY_RESOURCE_TYPE = "apigateway"]
[#assign AWS_APIGATEWAY_DEPLOY_RESOURCE_TYPE = "apiDeploy"]
[#assign AWS_APIGATEWAY_STAGE_RESOURCE_TYPE = "apiStage"]
[#assign AWS_APIGATEWAY_DOMAIN_RESOURCE_TYPE = "apiDomain"]
[#assign AWS_APIGATEWAY_AUTHORIZER_RESOURCE_TYPE = "apiAuthorizer"]
[#assign AWS_APIGATEWAY_BASEPATHMAPPING_RESOURCE_TYPE = "apiBasePathMapping"]
[#assign AWS_APIGATEWAY_USAGEPLAN_RESOURCE_TYPE = "apiUsagePlan"]
[#assign AWS_APIGATEWAY_APIKEY_RESOURCE_TYPE = "apiKey"]

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
[#assign APIGATEWAY_COMPONENT_DOCS_EXTENSION = "docs"]

[#assign componentConfiguration +=
    {
        APIGATEWAY_COMPONENT_TYPE : [
            {
                "Name" : "Links",
                "Default" : {}
            },
            {
                "Name" : "WAF",
                "Children" : [
                    {
                        "Name" : "Enabled",
                        "Default" : true
                    },
                    {
                        "Name" : "IPAddressGroups",
                        "Default" : []
                    },
                    {
                        "Name" : "Default"
                    },
                    {
                        "Name" : "RuleDefault"
                    }
                ]
            },
            {
                "Name" : "CloudFront",
                "Children" : [
                    {
                        "Name" : "Enabled",
                        "Default" : true
                    },
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
                    }
                ]
            },
            {
                "Name" : "Certificate",
                "Children" : [
                    {
                        "Name" : "Enabled",
                        "Default" : true
                    },
                    {
                        "Name" : "*"
                    }
                ]
            },
            {
                "Name" : "Publish",
                "Children" : [
                    {
                        "Name"  : "Enabled",
                        "Default" : true
                    },
                    {
                        "Name" : "DnsNamePrefix",
                        "Default" : "docs"
                    },
                    {
                        "Name" : "IPAddressGroups",
                        "Default" : []
                    }
                ]
            },
            {
                "Name" : "Mapping",
                "Children" : [
                    {
                        "Name"  : "Enabled",
                        "Default" : true
                    },
                    {
                        "Name" : "IncludeStage",
                        "Default" : true
                    }
                ]
            },
            {
                "Name" : "Service",
                "Children" : [
                    {
                        "Name" : "Name",
                        "Default" : "execute-api"
                    }
                ]
            }
        ]
    }]

[#function getAPIGatewayState occurrence]
    [#local core = occurrence.Core]
    [#local configuration = occurrence.Configuration]

    [#local apiId = formatResourceId("api", core.Id)]

    [#-- Resource Id doesn't follow the resource type for backwards compatability --]
    [#if getExistingReference(formatResourceId("api", core.Id))?has_content ]
        [#local apiId = formatResourceId("api", core.Id)]
    [#else ]
        [#local apiId = formatResourceId(AWS_APIGATEWAY_RESOURCE_TYPE, core.Id)]
    [/#if]
    [#local apiName = formatComponentFullName(core.Tier, core.Component, occurrence)]

    [#local stageId = formatResourceId(AWS_APIGATEWAY_STAGE_RESOURCE_TYPE, core.Id)]
    [#local stageName = core.Version.Name]

    [#local docsId = formatS3Id(core.Id, APIGATEWAY_COMPONENT_DOCS_EXTENSION)]

    [#local cfId = formatDependentCFDistributionId(apiId)]

    [#local internalFqdn =
        formatDomainName(
            getExistingReference(apiId),
            configuration.Service.Name,
            regionId,
            "amazonaws.com") ]

    [#local fqdn = internalFqdn]
    [#local signingFqdn = internalFqdn]
    [#local mappingStage = ""]
    [#local versionPath = "/" + stageName]
    [#local certificateId = "" ]
    [#local docsName =
            formatName(
                configuration.Publish.DnsNamePrefix,
                formatOccurrenceBucketName(occurrence))]

    [#if configuration.Certificate.Configured && configuration.Certificate.Enabled ]
        [#local certificateObject = getCertificateObject(configuration.Certificate!"", segmentId, segmentName)]
        [#local hostName = getHostName(certificateObject, occurrence)]
        [#local certificateId = formatDomainCertificateId(certificateObject, hostName) ]

        [#if configuration.Mapping.Configured && configuration.Mapping.Enabled ]
            [#local fqdn = formatDomainName(hostName, certificateObject.Domain.Name)]
            [#local docsName = formatDomainName(configuration.Publish.DnsNamePrefix, fqdn) ]
            [#local signingFqdn = fqdn]
            [#if configuration.Mapping.IncludeStage]
                [#local mappingStage = stageName ]
                [#local versionPath = "" ]
            [/#if]

            [#if configuration.CloudFront.Configured && configuration.CloudFront.Enabled]
                [#local signingFqdn = formatDomainName(formatName("sig4", hostName), certificateObject.Domain.Name)]
            [/#if]
        [#else]
            [#if configuration.CloudFront.Configured && configuration.CloudFront.Enabled]
                [#local fqdn = formatDomainName(hostName, certificateObject.Domain.Name)]
                [#local docsName = formatDomainName(configuration.Publish.DnsNamePrefix, fqdn) ]
            [/#if]
        [/#if]
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
                "apidomain" : {
                    "Id" : formatDependentResourceId(AWS_APIGATEWAY_DOMAIN_RESOURCE_TYPE, apiId),
                    "Fqdn" : signingFqdn,
                    "CertificateId" : certificateId,
                    "Type" : AWS_APIGATEWAY_DOMAIN_RESOURCE_TYPE
                },
                "apibasepathmapping" : {
                    "Id" : formatDependentResourceId(AWS_APIGATEWAY_BASEPATHMAPPING_RESOURCE_TYPE, stageId),
                    "Stage" : mappingStage,
                    "Type" : AWS_APIGATEWAY_BASEPATHMAPPING_RESOURCE_TYPE
                },
                "apiusageplan" : {
                    "Id" : formatDependentResourceId(AWS_APIGATEWAY_USAGEPLAN_RESOURCE_TYPE, cfId),
                    "Name" : formatComponentFullName(core.Tier, core.Component, occurrence),
                    "Type" : AWS_APIGATEWAY_USAGEPLAN_RESOURCE_TYPE
                },
                "invalidlogmetric" : {
                    "Id" : formatDependentLogMetricId(stageId, "invalid"),
                    "Name" : "Invalid",
                    "Type" : AWS_CLOUDWATCH_LOG_METRIC_RESOURCE_TYPE
                },
                "invalidalarm" : {
                    "Id" : formatDependentAlarmId(stageId, "invalid"),
                    "Name" : formatComponentAlarmName(core.Tier, core.Component, occurrence,"invalid"),
                    "Type" : AWS_CLOUDWATCH_ALARM_RESOURCE_TYPE
                },
                "cf" : {
                    "Id" : cfId,
                    "Name" : formatComponentCFDistributionName(core.Tier, core.Component, occurrence),
                    "CertificateId" : certificateId,
                    "Fqdn" : fqdn,
                    "Type" : AWS_CLOUDFRONT_DISTRIBUTION_RESOURCE_TYPE
                },
                "cforigin" : {
                    "Id" : "apigateway",
                    "Fqdn" : signingFqdn,
                    "Type" : AWS_CLOUDFRONT_ORIGIN_RESOURCE_TYPE
                },
                "wafacl" : {
                    "Id" : formatDependentWAFAclId(apiId),
                    "Name" : formatComponentWAFAclName(core.Tier, core.Component, occurrence),
                    "Type" : AWS_WAF_ACL_RESOURCE_TYPE
                },
                "docs" : {
                    "Id" : docsId,
                    "Name" : docsName,
                    "Type" : AWS_S3_RESOURCE_TYPE
                },
                "docspolicy" : {
                    "Id" : formatBucketPolicyId(core.Id, APIGATEWAY_COMPONENT_DOCS_EXTENSION),
                    "Type" : AWS_S3_BUCKET_POLICY_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "FQDN" : fqdn,
                "URL" : "https://" + fqdn + versionPath,
                "SIGNING_SERVICE_NAME" : configuration.Service.Name,
                "SIGNING_FQDN" : signingFqdn,
                "INTERNAL_FQDN" : internalFqdn,
                "INTERNAL_URL" : "https://" + internalFqdn + versionPath,
                "INTERNAL_PATH" : versionPath,
                "DOCS_URL" : "http://" + getExistingReference(docsId, NAME_ATTRIBUTE_TYPE)
            },
            "Roles" : {
                "Outbound" : {
                    "default" : "invoke",
                    "invoke" : apigatewayInvokePermission(apiId, stageName)
                },
                "Inbound" : {
                    "invoke" : {
                        "Principal" : "apigateway.amazonaws.com",
                        "SourceArn" : formatInvokeApiGatewayArn(apiId, stageName)
                    }
                }
            }
        }
    ]
[/#function]