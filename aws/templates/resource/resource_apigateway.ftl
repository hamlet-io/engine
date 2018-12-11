[#-- API Gateway --]

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

