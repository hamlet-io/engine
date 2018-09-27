[#-- Lambda --]

[#-- Resources --]
[#assign AWS_LAMBDA_RESOURCE_TYPE = "lambda"]
[#assign AWS_LAMBDA_FUNCTION_RESOURCE_TYPE = "lambda"]
[#assign AWS_LAMBDA_PERMISSION_RESOURCE_TYPE = "permission"]
[#assign AWS_LAMBDA_EVENT_SOURCE_TYPE = "source"]

[#function formatLambdaPermissionId occurrence extensions...]
    [#return formatResourceId(
                AWS_LAMBDA_PERMISSION_RESOURCE_TYPE,
                occurrence.Core.Id,
                extensions)]
[/#function]

[#function formatLambdaEventSourceId occurrence extensions...]
    [#return formatResourceId(
                AWS_LAMBDA_EVENT_SOURCE_TYPE,
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
            {
                "Name" : ["Fragment", "Container"],
                "Type" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Name" : "Handler",
                "Type" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Name" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Name" : "LogMetrics",
                "Subobjects" : true,
                "Children" : logMetricChildrenConfiguration
            },
            {
                "Name" : "LogWatchers",
                "Subobjects" : true,
                "Children" : logWatcherChildrenConfiguration
            },
            {
                "Name" : "Alerts",
                "Subobjects" : true,
                "Children" : alertChildrenConfiguration
            },
            {
                "Name" : ["Memory", "MemorySize"],
                "Type" : NUMBER_TYPE,
                "Default" : 0
            },
            {
                "Name" : "RunTime",
                "Type" : STRING_TYPE,
                "Values" : ["nodejs", "nodejs4.3", "nodejs6.10", "nodejs8.10", "java8", "python2.7", "python3.6", "dotnetcore1.0", "dotnetcore2.0", "dotnetcore2.1", "nodejs4.3-edge", "go1.x"],
                "Mandatory" : true
            },
            {
                "Name" : "Schedules",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Name" : "Expression",
                        "Type" : STRING_TYPE,
                        "Default" : "rate(6 minutes)"
                    },
                    {
                        "Name" : "InputPath",
                        "Type" : STRING_TYPE,
                        "Default" : "/healthcheck"
                    },
                    {
                        "Name" : "Input",
                        "Type" : OBJECT_TYPE,
                        "Default" : {}
                    }
                ]
            },
            {
                "Name" : "Timeout",
                "Type" : NUMBER_TYPE,
                "Default" : 0
            },
            {
                "Name" : "VPCAccess",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Name" : "UseSegmentKey",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Name" : "Permissions",
                "Children" : [
                    {
                        "Name" : "Decrypt",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Name" : "AsFile",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Name" : "AppData",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Name" : "AppPublic",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Name" : "PredefineLogGroup",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Name" : "Environment",
                "Children" : settingsChildConfiguration
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

    [#local id = formatResourceId(AWS_LAMBDA_FUNCTION_RESOURCE_TYPE, core.Id)]

    [#local lgId = formatLogGroupId(core.Id)]
    [#local lgName = formatAbsolutePath("aws", "lambda", core.FullName)]

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
                    "Name" : lgName,
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
                "Inbound" : {
                    "logwatch" : {
                        "Principal" : "logs." + regionId + "amazonaws.com",
                        "LogGroupIds" : [ lgId ]
                    }
                },
                "Outbound" : {
                    "invoke" : lambdaInvokePermission(id)
                }
            }
        }
    ]
[/#function]