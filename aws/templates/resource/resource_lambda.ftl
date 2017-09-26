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
    [@cfTemplate
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
            container.Environment?has_content?then(
                {
                    "Environment" : container.Environment
                },
                {}
            ) +
            (container.MemorySize > 0)?then(
                {
                    "MemorySize" : container.MemorySize
                },
                {}
            ) +
            (container.Timeout > 0)?then(
                {
                    "Timeout" : container.Timeout
                },
                {}
            ) +
            container.UseSegmentKey?then(
                {
                    "KmsKeyArn" : getReference(formatSegmentCMKId(), ARN_ATTRIBUTE_TYPE)
                },
                {}
            ) + 
            securityGroupIds?has_content?then(
                {
                    "VpcConfig" : {
                        "SecurityGroupIds" : getReferences(securityGroupIds),
                        "SubnetIds" : getSubnets(tier)
                    }
                },
                {}
            )
        outputs=LAMBDA_FUNCTION_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]
