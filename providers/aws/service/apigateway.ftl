[#ftl]

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

[#assign APIGATEWAY_USAGEPLAN_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
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
        AWS_APIGATEWAY_USAGEPLAN_RESOURCE_TYPE : APIGATEWAY_USAGEPLAN_OUTPUT_MAPPINGS,
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

[#macro createAPIUsagePlan mode id name stages=[] dependencies="" ]
    [@cfResource
        mode=mode
        id=id
        type="AWS::ApiGateway::UsagePlan"
        properties=
            {
                "ApiStages" : stages,
                "UsagePlanName" : name
            }
        outputs=APIGATEWAY_USAGEPLAN_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]

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

[#macro createAPIUsagePlanMember mode id planId apikeyId dependencies="" ]
    [@cfResource
        mode=mode
        id=id
        type="AWS::ApiGateway::UsagePlanKey"
        properties=
            {
                "KeyId" : getReference(apikeyId),
                "KeyType" : "API_KEY",
                "UsagePlanId" : getReference(planId)
            }
        outputs={}
        dependencies=dependencies
    /]
[/#macro]

