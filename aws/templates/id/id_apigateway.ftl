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

[#function formatAPIGatewayLambdaPermissionId tier component link fn extensions...]
    [#return formatComponentResourceId(
                "apiLambdaPermission",
                tier,
                component,
                extensions,
                link,
                fn)]
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
            }
        ]
    }]
    
[#function getAPIGatewayState occurrence]
    [#local id = formatAPIGatewayId(occurrence.Tier, occurrence.Component, occurrence)]
    [#local internalFqdn =
        formatDomainName(
            getExistingReference(id),
            "execute-api",
            regionId,
            "amazonaws.com") ]

    [#if occurrence.Certificate.Configured && occurrence.Certificate.Enabled ]
            [#local certificateObject = getCertificateObject(occurrence.Certificate!"", segmentId, segmentName) ]
            [#local hostName = getHostName(certificateObject, occurrence.Tier, occurrence.Component, occurrence) ]
            [#local fqdn = formatDomainName(hostName, certificateObject.Domain.Name)]
            [#local signingFqdn = formatDomainName(formatName("sig4", hostName), certificateObject.Domain.Name) ] 

    [#else]
            [#local fqdn = internalFqdn]
            [#local signingFqdn = internalFqdn]
    [/#if]

    [#return
        {
            "Resources" : {
                "primary" : {
                    "Id" : id
                }
            },
            "Attributes" : {
                "FQDN" : fqdn,
                "URL" : "https://" + fqdn,
                "SIGNING_FQDN" : signingFqdn,
                "SIGNING_URL" : "https://" + signingFqdn,
                "INTERNAL_FQDN" : internalFqdn,
                "INTERNAL_URL" : "https://" + internalFqdn
            },
            "Policy" : apigatewayInvokePermission(id, occurrence.Version.Id)
        }
    ]
[/#function]