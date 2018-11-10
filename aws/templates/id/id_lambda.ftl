[#-- Lambda --]

[#-- Resources --]
[#assign AWS_LAMBDA_RESOURCE_TYPE = "lambda"]
[#assign AWS_LAMBDA_FUNCTION_RESOURCE_TYPE = "lambda"]
[#assign AWS_LAMBDA_PERMISSION_RESOURCE_TYPE = "permission"]
[#assign AWS_LAMBDA_EVENT_SOURCE_TYPE = "source"]
[#assign AWS_LAMBDA_VERSION_RESOURCE_TYPE = "lambdaVersion" ]

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
            "Properties" : [
                {
                    "Type"  : "Description",
                    "Value" : "Container for a Function as a Service deployment"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "application"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "DeploymentType",
                    "Type" : STRING_TYPE,
                    "Values" : ["EDGE", "REGIONAL"],
                    "Default" : "REGIONAL"
                }
            ],
            "Components" : [
                {
                    "Type" : LAMBDA_FUNCTION_COMPONENT_TYPE,
                    "Component" : "Functions",
                    "Link" : "Function"
                }
            ]
        },
        LAMBDA_FUNCTION_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type"  : "Description",
                    "Value" : "A specific entry point for the lambda deployment"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "application"
                }
            ],
            "Attributes" : [
                {
                    "Names" : ["Fragment", "Container"],
                    "Type" : STRING_TYPE,
                    "Default" : ""
                },
                {
                    "Names" : "Handler",
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "LogMetrics",
                    "Subobjects" : true,
                    "Children" : logMetricChildrenConfiguration
                },
                {
                    "Names" : "LogWatchers",
                    "Subobjects" : true,
                    "Children" : logWatcherChildrenConfiguration
                },
                {
                    "Names" : "Alerts",
                    "Subobjects" : true,
                    "Children" : alertChildrenConfiguration
                },
                {
                    "Names" : ["Memory", "MemorySize"],
                    "Type" : NUMBER_TYPE,
                    "Default" : 0
                },
                {
                    "Names" : "RunTime",
                    "Type" : STRING_TYPE,
                    "Values" : ["nodejs", "nodejs4.3", "nodejs6.10", "nodejs8.10", "java8", "python2.7", "python3.6", "dotnetcore1.0", "dotnetcore2.0", "dotnetcore2.1", "nodejs4.3-edge", "go1.x"],
                    "Mandatory" : true
                },
                {
                    "Names" : "Schedules",
                    "Subobjects" : true,
                    "Children" : [
                        {
                            "Names" : "Expression",
                            "Type" : STRING_TYPE,
                            "Default" : "rate(6 minutes)"
                        },
                        {
                            "Names" : "InputPath",
                            "Type" : STRING_TYPE,
                            "Default" : "/healthcheck"
                        },
                        {
                            "Names" : "Input",
                            "Type" : OBJECT_TYPE,
                            "Default" : {}
                        }
                    ]
                },
                {
                    "Names" : "Timeout",
                    "Type" : NUMBER_TYPE,
                    "Default" : 0
                },
                {
                    "Names" : "VPCAccess",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "UseSegmentKey",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Permissions",
                    "Children" : [
                        {
                            "Names" : "Decrypt",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "AsFile",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "AppData",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        },
                        {
                            "Names" : "AppPublic",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : true
                        }
                    ]
                },
                {
                    "Names" : "PredefineLogGroup",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Environment",
                    "Children" : settingsChildConfiguration
                },
                {
                    "Names" : "Versioned",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                }
            ]
        }
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

[#function getFunctionState occurrence parent]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution ]

    [#local parentSolution = parent.Configuration.Solution ]

    [#local id = formatResourceId(AWS_LAMBDA_FUNCTION_RESOURCE_TYPE, core.Id)]
    [#local versionId = formatResourceId(AWS_LAMBDA_VERSION_RESOURCE_TYPE, core.Id)]

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
            } + 
            attributeIfTrue(
                "version",
                solution.Versioned,
                {
                    "Id" : versionId,
                    "Type" : AWS_LAMBDA_VERSION_RESOURCE_TYPE
                }
            ),
            "Attributes" : {
                "REGION" : regionId,
                "ARN" : valueIfTrue(
                            getExistingReference( versionId ),
                            solution.Versioned
                            formatArn(
                                regionObject.Partition,
                                "lambda", 
                                regionId,
                                accountObject.AWSId,
                                "function:" + core.FullName,
                                true)
                ),
                "NAME" : core.FullName,
                "DEPLOYMENT_TYPE": parentSolution.DeploymentType
            },
            "Roles" : {
                "Inbound" : {
                    "logwatch" : {
                        "Principal" : "logs." + regionId + ".amazonaws.com",
                        "LogGroupIds" : [ lgId ]
                    }
                },
                "Outbound" : {
                    "default" : "invoke",
                    "invoke" : lambdaInvokePermission(id)
                }
            }
        }
    ]
[/#function]