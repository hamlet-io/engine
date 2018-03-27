[#-- API Gateway --]

[#assign APIGATEWAY_COMPONENT_TYPE = "apigateway"]

[#assign APIGATEWAY_RESOURCE_TYPE = "apigateway"]
[#assign APIGATEWAY_DEPLOY_RESOURCE_TYPE = "apiDeploy"]
[#assign APIGATEWAY_STAGE_RESOURCE_TYPE = "apiStage"]
[#assign APIGATEWAY_DOMAIN_RESOURCE_TYPE = "apiDomain"]
[#assign APIGATEWAY_AUTHORIZER_RESOURCE_TYPE = "apiAuthorizer"]
[#assign APIGATEWAY_BASEPATHMAPPING_RESOURCE_TYPE = "apiBasePathMapping"]
[#assign APIGATEWAY_USAGEPLAN_RESOURCE_TYPE = "apiUsagePlan"]
[#assign APIGATEWAY_APIKEY_RESOURCE_TYPE = "apiKey"]

[#assign APIGATEWAY_DOCS_EXTENSION = "docs"]

[#function formatDependentAPIGatewayAuthorizerId resourceId extensions...]
    [#return formatDependentResourceId(
                APIGATEWAY_AUTHORIZER_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

[#function formatDependentAPIGatewayAPIKeyId resourceId extensions...]
    [#return formatDependentResourceId(
                APIGATEWAY_APIKEY_RESOURCE_TYPE,
                resourceId,
                extensions)]
[/#function]

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
                "Name" : "IncludePathInUrls",
                "Default" : true
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
        [#local apiId = formatResourceId(APIGATEWAY_RESOURCE_TYPE, core.Id)]
    [/#if]
    
    [#local apiName = formatComponentFullName(core.Tier, core.Component, occurrence)]
    [#local stageId = formatResourceId(APIGATEWAY_STAGE_RESOURCE_TYPE, core.Id)]

    [#local docsId = formatS3Id(core.Id, APIGATEWAY_DOCS_EXTENSION)]
    [#local cfId = formatDependentCFDistributionId(apiId)]

    [#local internalFqdn =
        formatDomainName(
            getExistingReference(apiId),
            "execute-api",
            regionId,
            "amazonaws.com") ]

    [#if configuration.Certificate.Configured && configuration.Certificate.Enabled ]
            [#local certificateObject = getCertificateObject(configuration.Certificate!"", segmentId, segmentName)]
            [#local hostName = getHostName(certificateObject, core.Tier, core.Component, occurrence)]
            [#local fqdn = formatDomainName(hostName, certificateObject.Domain.Name)]
            [#local signingFqdn = formatDomainName(formatName("sig4", hostName), certificateObject.Domain.Name)] 
    [#else]
            [#local fqdn = internalFqdn]
            [#local signingFqdn = internalFqdn]
    [/#if]

    [#-- Paths are tricky as sometimes the API gateway "consumes" version path. --]
    [#-- So the caller needs to provide it but the implementer doesn't see it.  --]
    [#local versionPath =
        valueIfTrue(
            "/" + core.Version.Id,
            configuration.IncludePathInUrls,
            ""
        ) ]

    [#-- For now assume the path is seen by the implementation --]
    [#-- A later change will refine this once behaviour of the --]
    [#-- API Gateway is confirmed                              --]
    [#local internalPath = core.Version.Id ]
    [#return
        {
            "Resources" : {
                "apigateway" : {
                    "Id" : apiId,
                    "Name" : apiName
                },
                "apideploy" : {
                    "Id" : formatResourceId(APIGATEWAY_DEPLOY_RESOURCE_TYPE, core.Id, runId)
                },
                "apistage" : {
                    "Id" : stageId,
                    "Name" : core.Version.Name
                },
                "apidomain" : {
                    "Id" : formatDependentResourceId(APIGATEWAY_DOMAIN_RESOURCE_TYPE, apiId)
                },
                "apibasepathmapping" : { 
                    "Id" : formatDependentResourceId(APIGATEWAY_BASEPATHMAPPING_RESOURCE_TYPE, stageId)
                },
                "apiusageplan" : {
                    "Id" : formatDependentResourceId(APIGATEWAY_USAGEPLAN_RESOURCE_TYPE, cfId),
                    "Name" : formatComponentFullName(core.Tier, core.Component, occurrence)
                },
                "invalidlogmetric" : {
                    "Id" : formatDependentLogMetricId(stageId, "invalid"),
                    "Name" : "Invalid"
                },
                "invalidalarm" : {
                    "Id" : formatDependentAlarmId(stageId, "invalid"),
                    "Name" : formatComponentAlarmName(core.Tier, core.Component, occurrence,"invalid")
                },
                "cf" : {
                    "Id" : cfId,
                    "Name" : formatComponentCFDistributionName(core.Tier, core.Component, occurrence)
                },
                "cforigin" : {
                    "Id" : "apigateway"
                },
                "wafacl" : { 
                    "Id" : formatDependentWAFAclId(apiId),
                    "Name" : formatComponentWAFAclName(core.Tier, core.Component, occurrence)
                },
                "docs" : {
                    "Id" : docsId
                },
                "docspolicy" : {
                    "Id" : formatBucketPolicyId(core.Id, APIGATEWAY_DOCS_EXTENSION)
                }
            },
            "Attributes" : {
                "FQDN" : fqdn,
                "URL" : "https://" + fqdn,
                "SIGNING_FQDN" : signingFqdn,
                "SIGNING_URL" : "https://" + signingFqdn + versionPath,
                "INTERNAL_FQDN" : internalFqdn,
                "INTERNAL_URL" : "https://" + internalFqdn + versionPath,
                "DOCS_URL" : "http://" + getExistingReference(docsId, NAME_ATTRIBUTE_TYPE)
            },
            "Roles" : {
                "Outbound" : {
                    "default" : "invoke",
                    "invoke" : apigatewayInvokePermission(apiId, core.Version.Name)
                },
                "Inbound" : {
                    "invoke" : {
                        "Principal" : "apigateway.amazonaws.com",
                        "SourceArn" : formatInvokeApiGatewayArn(apiId, core.Version.Name)
                    }
                }
            }
        }
    ]
[/#function]