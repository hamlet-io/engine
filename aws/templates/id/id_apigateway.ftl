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

