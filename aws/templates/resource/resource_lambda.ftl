[#-- Lambda --]

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

[#assign LAMBDA_PERMISSION_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]

[#assign outputMappings +=
    {
        AWS_LAMBDA_FUNCTION_RESOURCE_TYPE : LAMBDA_FUNCTION_OUTPUT_MAPPINGS,
        AWS_LAMBDA_PERMISSION_RESOURCE_TYPE : LAMBDA_PERMISSION_OUTPUT_MAPPINGS
    }
]
[#macro createLambdaFunction mode id container roleId securityGroupIds=[] subnetIds=[] dependencies=""]
    [@cfResource
        mode=mode
        id=id
        type="AWS::Lambda::Function"
        properties=
            {
                "Code" : {
                    "S3Bucket" : container.S3Bucket,
                    "S3Key" : container.S3Key
                },                                            
                "FunctionName" : container.Name,
                "Description" : container.Description,
                "Handler" : container.Handler,
                "Role" : getReference(roleId, ARN_ATTRIBUTE_TYPE),
                "Runtime" : container.RunTime
            } + 
            attributeIfContent("Environment", container.Environment!{}, {"Variables" : container.Environment}) +
            attributeIfTrue("MemorySize", container.MemorySize > 0, container.MemorySize) +
            attributeIfTrue("Timeout", container.Timeout > 0, container.Timeout) +
            attributeIfTrue(
                "KmsKeyArn",
                container.UseSegmentKey!false,
                getReference(formatSegmentCMKId(), ARN_ATTRIBUTE_TYPE)) + 
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

[#macro createLambdaPermission mode id targetId source={} sourcePrincipal="" sourceId="" dependencies=""]
    [@cfResource
        mode=mode
        id=id
        type="AWS::Lambda::Permission"
        properties=
            {
                "FunctionName" : getReference(targetId),
                "Action" : "lambda:InvokeFunction"
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
