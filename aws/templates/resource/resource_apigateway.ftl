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
[#assign outputMappings +=
    {
        APIGATEWAY_RESOURCE_TYPE : APIGATEWAY_OUTPUT_MAPPINGS
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
