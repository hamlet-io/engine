[#ftl]

[#assign LAMBDA_FUNCTION_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "Attribute" : "Arn"
        }
    }
]

[#assign metricAttributes +=
    {
        AWS_LAMBDA_FUNCTION_RESOURCE_TYPE : {
            "Namespace" : "AWS/Lambda",
            "Dimensions" : {
                "FunctionName" : {
                    "ResourceProperty" : "Name"
                }
            }
        }
    }
]

[#assign LAMBDA_VERSION_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]

[#assign LAMBDA_PERMISSION_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]

[#assign LAMBDA_EVENT_SOURCE_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]

[#assign outputMappings +=
    {
        AWS_LAMBDA_FUNCTION_RESOURCE_TYPE : LAMBDA_FUNCTION_OUTPUT_MAPPINGS,
        AWS_LAMBDA_PERMISSION_RESOURCE_TYPE : LAMBDA_PERMISSION_OUTPUT_MAPPINGS,
        AWS_LAMBDA_EVENT_SOURCE_TYPE : LAMBDA_EVENT_SOURCE_MAPPINGS
    }
]
[#macro createLambdaFunction mode id settings roleId securityGroupIds=[] subnetIds=[] dependencies=""]
    [@cfResource
        mode=mode
        id=id
        type="AWS::Lambda::Function"
        properties=
            {
                "Code" :
                    valueIfContent(
                        {
                            "ZipFile" : settings.ZipFile!""
                        },
                        settings.ZipFile!"",
                        {
                            "S3Bucket" : settings.S3Bucket,
                            "S3Key" : settings.S3Key
                        }),
                "FunctionName" : settings.Name,
                "Description" : settings.Description,
                "Handler" : settings.Handler,
                "Role" : getReference(roleId, ARN_ATTRIBUTE_TYPE),
                "Runtime" : settings.RunTime
            } +
            attributeIfContent("Environment", settings.Environment!{}, {"Variables" : settings.Environment}) +
            attributeIfTrue("MemorySize", settings.MemorySize > 0, settings.MemorySize) +
            attributeIfTrue("Timeout", settings.Timeout > 0, settings.Timeout) +
            attributeIfTrue(
                "KmsKeyArn",
                settings.Encrypted!false,
                getReference(settings.KMSKeyId, ARN_ATTRIBUTE_TYPE)) +
            attributeIfContent(
                "VpcConfig",
                securityGroupIds,
                {
                    "SecurityGroupIds" : getReferences(securityGroupIds),
                    "SubnetIds" : getReferences(subnetIds)
                })
        outputs=LAMBDA_FUNCTION_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]

[#macro createLambdaVersion mode id
            targetId
            codeHash=""
            description=""
            dependencies="" ]
    [@cfResource
        mode=mode
        id=id
        type="AWS::Lambda::Version"
        properties=
            {
                "FunctionName" : getReference(targetId)
            } +
            attributeIfContent(
                "Description",
                description
            ) +
            attributeIfContent(
                "CodeSha256",
                codeHash
            )
        outputs=LAMBDA_VERSION_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]

[#macro createLambdaPermission mode id targetId action="lambda:InvokeFunction" source={} sourcePrincipal="" sourceId="" dependencies=""]
    [@cfResource
        mode=mode
        id=id
        type="AWS::Lambda::Permission"
        properties=
            {
                "FunctionName" : getReference(targetId),
                "Action" : action
            } +
            valueIfContent(
                source,
                source,
                {
                    "Principal" : sourcePrincipal,
                    "SourceArn" : getReference(sourceId, ARN_ATTRIBUTE_TYPE)
                }
            )
        outputs=LAMBDA_PERMISSION_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]

[#macro createLambdaEventSource mode id targetId source enabled=true batchSize="" startingPosition="" dependencies=""]

    [@cfResource
        mode=mode
        id=id
        type="AWS::Lambda::EventSourceMapping"
        properties=
            {
                "Enabled" : enabled,
                "EventSourceArn" : getArn(source),
                "FunctionName" : getReference(targetId)
            } +
            attributeIfContent("BatchSize", batchSize) +
            attributeIfContent("StartingPosition", startingPosition)
        outputs=LAMBDA_EVENT_SOURCE_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]
