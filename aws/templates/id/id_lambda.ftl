[#-- Lambda --]

[#assign LAMBDA_RESOURCE_TYPE = "lambda" ]
[#assign LAMBDA_FUNCTION_RESOURCE_TYPE = "lambda" ]
[#assign LAMBDA_PERMISSION_RESOURCE_TYPE = "permission" ]

[#assign LAMBDA_COMPONENT_TYPE = "lambda" ]
[#assign LAMBDA_FUNCTION_COMPONENT_TYPE = "function" ]

[#function formatLambdaPermissionId occurrence extensions...]
    [#return formatResourceId(
                LAMBDA_PERMISSION_RESOURCE_TYPE,
                occurrence.Core.Id,
                extensions)]
[/#function]

[#function formatLambdaArn lambdaId account={ "Ref" : "AWS::AccountId" }]
    [#return
        formatRegionalArn(
            "lambda",
            getReference(lambdaId))]
[/#function]

[#assign componentConfiguration +=
    {
        LAMBDA_COMPONENT_TYPE : {
            "Attributes" : [],
            "Components" : [
                {
                    "Type" : LAMBDA_FUNCTION_COMPONENT_TYPE,
                    "Component" : "Functions",
                    "Link" : "Function"
                }
            ]
        },
        LAMBDA_FUNCTION_COMPONENT_TYPE : [
            "Container",
            {
                "Name" : "Handler",
                "Mandatory" : true
            },
            {
                "Name" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Name" : ["Memory", "MemorySize"],
                "Default" : 0
            },
            {
                "Name" : "RunTime",
                "Mandatory" : true
            },
            {
                "Name" : "Schedules",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Name" : "Enabled",
                        "Default" : true
                    },
                    {
                        "Name" : "Expression",
                        "Default" : "rate(30 minutes)"
                    },
                    {
                        "Name" : "InputPath",
                        "Default" : "/healthcheck"
                    }
                ]
            },
            {
                "Name" : "Timeout",
                "Default" : 0
            },
            {
                "Name" : "VPCAccess",
                "Default" : true
            },
            {
                "Name" : "UseSegmentKey",
                "Default" : false
            }
        ]
    }
]
    
[#function getLambdaState occurrence]
    [#local core = occurrence.Core]

    [#return
        {
            "Resources" : {
                "lambda" : {
                    "Id" : formatResourceId(LAMBDA_RESOURCE_TYPE, core.Id),
                    "Name" : formatSegmentFullName(core.Name)
                }
            },
            "Attributes" : {
                "REGION" : regionId
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]

[#function getFunctionState occurrence]
    [#local core = occurrence.Core]

    [#return
        {
            "Resources" : {
                "function" : {
                    "Id" : formatResourceId(LAMBDA_FUNCTION_RESOURCE_TYPE, core.Id),
                    "Name" : formatSegmentFullName(core.Name)
                }
            },
            "Attributes" : {
                "REGION" : regionId
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]
