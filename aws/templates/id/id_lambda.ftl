[#-- Lambda --]

[#-- Resources --]
[#assign AWS_LAMBDA_RESOURCE_TYPE = "lambda"]
[#assign AWS_LAMBDA_FUNCTION_RESOURCE_TYPE = "lambda"]
[#assign AWS_LAMBDA_PERMISSION_RESOURCE_TYPE = "permission"]

[#function formatLambdaPermissionId occurrence extensions...]
    [#return formatResourceId(
                AWS_LAMBDA_PERMISSION_RESOURCE_TYPE,
                occurrence.Core.Id,
                extensions)]
[/#function]

[#function formatLambdaArn lambdaId account={ "Ref" : "AWS::AccountId" }]
    [#return
        formatRegionalArn(
            "lambda",
            getReference(lambdaId))]
[/#function]

[#-- Components --]
[#assign LAMBDA_COMPONENT_TYPE = "lambda"]
[#assign LAMBDA_FUNCTION_COMPONENT_TYPE = "function"]

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
                "Name" : "Metrics",
                "Subobjects" : true,
                "Children" : metricChildrenConfiguration
            },
            {
                "Name" : "Alerts",
                "Subobjects" : true,
                "Children" : alertChildrenConfiguration
            }
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
                        "Default" : "rate(6 minutes)"
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
            },
            {
                "Name" : "Permissions",
                "Children" : [
                    {
                        "Name" : "Decrypt",
                        "Default" : true
                    },
                    {
                        "Name" : "AsFile",
                        "Default" : true
                    },
                    {
                        "Name" : "AppData",
                        "Default" : true
                    },
                    {
                        "Name" : "AppPublic",
                        "Default" : true
                    }
                ]
            },
            {
                "Name" : "PredefineLogGroup",
                "Default" : false
            },
            {
                "Name" : "EnvironmentAsFile",
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
                    "Id" : formatResourceId(AWS_LAMBDA_RESOURCE_TYPE, core.Id),
                    "Name" : core.FullName,
                    "Type" : AWS_LAMBDA_RESOURCE_TYPE
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

    [#assign id = formatResourceId(AWS_LAMBDA_FUNCTION_RESOURCE_TYPE, core.Id)]

    [#return
        {
            "Resources" : {
                "function" : {
                    "Id" : id,
                    "Name" : core.FullName,
                    "Type" : AWS_LAMBDA_FUNCTION_RESOURCE_TYPE
                },
                "lg" : {
                    "Id" : formatLogGroupId(core.Id),
                    "Name" : formatAbsolutePath("aws", "lambda", core.FullName),
                    "Type" : AWS_CLOUDWATCH_LOG_GROUP_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "REGION" : regionId,
                "ARN" : formatArn(
                            regionObject.Partition,
                            "lambda", 
                            regionId,
                            accountObject.AWSId,
                            "function:" + core.FullName,
                            true),
                "NAME" : core.FullName
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {
                    "invoke" : lambdaInvokePermission(id)
                }
            }
        }
    ]
[/#function]
