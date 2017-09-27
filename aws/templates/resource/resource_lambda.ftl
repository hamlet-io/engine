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

[#assign outputMappings +=
    {
        LAMBDA_FUNCTION_RESOURCE_TYPE : LAMBDA_FUNCTION_OUTPUT_MAPPINGS
    }
]

[#macro createLambdaFunction mode id container roleId securityGroupIds=[] dependencies=""]
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
            attributeIfContent("Environment", container.Environment!{}) +
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
                    "SubnetIds" : getSubnets(tier)
                })
        outputs=LAMBDA_FUNCTION_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]
