[#ftl]

[#-- Resources --]
[#assign AWS_APIGATEWAY_USAGEPLAN_RESOURCE_TYPE = "apiUsagePlan"]
[#assign AWS_APIGATEWAY_USAGEPLAN_MEMBER_RESOURCE_TYPE = "apiUsagePlanMember"]

[#assign APIGATEWAY_USAGEPLAN_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]

[#assign outputMappings +=
    {
        AWS_APIGATEWAY_USAGEPLAN_RESOURCE_TYPE : APIGATEWAY_USAGEPLAN_OUTPUT_MAPPINGS
    }
]

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

