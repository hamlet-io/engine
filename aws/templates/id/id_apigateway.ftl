[#-- API Gateway --]

[#assign APIGATEWAY_RESOURCE_TYPE = "api" ]

[#function formatAPIGatewayId tier component extensions...]
    [#return formatComponentResourceId(
                APIGATEWAY_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatAPIGatewayDeployId tier component extensions...]
    [#return formatComponentResourceId(
                "apiDeploy",
                tier,
                component,
                extensions)]
[/#function]

[#function formatAPIGatewayStageId tier component extensions...]
    [#return formatComponentResourceId(
                "apiStage",
                tier,
                component,
                extensions)]
[/#function]

[#function formatDependentAPIGatewayDomainId resourceId extensions...]
    [#return formatDependentResourceId(
                "apiDomain",
                resourceId,
                extensions)]
[/#function]

[#function formatDependentAPIGatewayAuthorizerId resourceId extensions... ]
    [#return formatDependentResourceId(
                "apiAuthorizer",
                resourceId,
                extensions)] 
[/#function]

[#function formatDependentAPIGatewayBasePathMappingId resourceId extensions...]
    [#return formatDependentResourceId(
                "apiBasePathMapping",
                resourceId,
                extensions)]
[/#function]

[#function formatDependentAPIGatewayUsagePlanId resourceId extensions...]
    [#return formatDependentResourceId(
                "apiUsagePlan",
                resourceId,
                extensions)]
[/#function]

[#function formatDependentAPIGatewayAPIKeyId resourceId extensions...]
    [#return formatDependentResourceId(
                "apiKey",
                resourceId,
                extensions)]
[/#function]

[#assign componentConfiguration +=
    {
        "apigateway" : [
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

    [#local id = formatAPIGatewayId(core.Tier, core.Component, occurrence)]
    [#local name = formatComponentFullName(core.Tier, core.Component, occurrence)]

    [#local internalFqdn =
        formatDomainName(
            getExistingReference(id),
            "execute-api",
            regionId,
            "amazonaws.com") ]

    [#if configuration.Certificate.Configured && configuration.Certificate.Enabled ]
            [#local certificateObject = getCertificateObject(configuration.Certificate!"", segmentId, segmentName) ]
            [#local hostName = getHostName(certificateObject, core.Tier, core.Component, occurrence) ]
            [#local fqdn = formatDomainName(hostName, certificateObject.Domain.Name)]
            [#local signingFqdn = formatDomainName(formatName("sig4", hostName), certificateObject.Domain.Name) ] 

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
                "gateway" : {
                    "Id" : id,
                    "Name" : name
                }
            },
            "Attributes" : {
                "FQDN" : fqdn,
                "URL" : "https://" + fqdn + versionPath,
                "DOCS_URL" : "http://docs." + fqdn,
                "SIGNING_FQDN" : signingFqdn,
                "SIGNING_URL" : "https://" + signingFqdn + versionPath,
                "INTERNAL_FQDN" : internalFqdn,
                "INTERNAL_URL" : "https://" + internalFqdn + versionPath,
                "INTERNAL_PATH" : internalPath
            },
            "Roles" : {
                "Outbound" : {
                    "default" : "invoke",
                    "invoke" : apigatewayInvokePermission(id, core.Version.Name)
                },
                "Inbound" : {
                    "invoke" : {
                        "Principal" : "apigateway.amazonaws.com",
                        "SourceArn" : formatInvokeApiGatewayArn(id, core.Version.Name)
                    }
                }
            }
        }
    ]
[/#function]