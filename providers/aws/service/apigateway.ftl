[#ftl]

[#-- Resources --]
[#assign AWS_APIGATEWAY_RESOURCE_TYPE = "apigateway"]
[#assign AWS_APIGATEWAY_DEPLOY_RESOURCE_TYPE = "apiDeploy"]
[#assign AWS_APIGATEWAY_STAGE_RESOURCE_TYPE = "apiStage"]
[#assign AWS_APIGATEWAY_DOMAIN_RESOURCE_TYPE = "apiDomain"]
[#assign AWS_APIGATEWAY_AUTHORIZER_RESOURCE_TYPE = "apiAuthorizer"]
[#assign AWS_APIGATEWAY_BASEPATHMAPPING_RESOURCE_TYPE = "apiBasePathMapping"]
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

[#assign APIGATEWAY_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ROOT_ATTRIBUTE_TYPE : {
            "Attribute" : "RootResourceId"
        }
    }
]

[#assign metricAttributes +=
    {
        AWS_APIGATEWAY_RESOURCE_TYPE : {
            "Namespace" : "AWS/ApiGateway",
            "Dimensions" : {
                "ApiName" : {
                    "ResourceProperty" : "Name"
                },
                "Stage" : {
                    "OtherResourceProperty" : {
                        "Id" : "apistage",
                        "Property" : "Name"
                    }
                }
            }
        }
    }
]

[#assign APIGATEWAY_APIKEY_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]
[#assign outputMappings +=
    {
        AWS_APIGATEWAY_RESOURCE_TYPE : APIGATEWAY_OUTPUT_MAPPINGS,
        AWS_APIGATEWAY_APIKEY_RESOURCE_TYPE : APIGATEWAY_APIKEY_OUTPUT_MAPPINGS
    }
]

[#function formatInvokeApiGatewayArn apiId stageName="" account={ "Ref" : "AWS::AccountId" }]
    [#return
        formatRegionalArn(
            "execute-api",
            formatTypedArnResource(
                getReference(apiId),
                valueIfContent(stageName + "/*", stageName, "*"),
                "/"
            )
        )
    ]
[/#function]

[#macro createAPIKey mode id name enabled=true distinctId=false description="" dependencies="" ]
    [@cfResource
        mode=mode
        id=id
        type="AWS::ApiGateway::ApiKey"
        properties=
            {
                "Enabled" : enabled,
                "GenerateDistinctId" : distinctId,
                "Name" : name
            } +
            attributeIfContent("Description", description)
        outputs=APIGATEWAY_APIKEY_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]

