[#-- Lambda --]

[#assign LAMBDA_RESOURCE_TYPE = "lambda" ]
[#assign LAMBDA_FUNCTION_RESOURCE_TYPE = "lambda" ]
[#assign LAMBDA_PERMISSION_RESOURCE_TYPE = "permission" ]

[#function formatLambdaId tier component extensions...]
    [#return formatComponentResourceId(
                LAMBDA_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#function formatLambdaFunctionId tier component fn extensions...]
    [#return formatComponentResourceId(
                LAMBDA_FUNCTION_RESOURCE_TYPE,
                tier,
                component,
                extensions,
                fn)]
[/#function]

[#function formatLambdaPermissionId tier component fn extensions...]
    [#return formatComponentResourceId(
                LAMBDA_PERMISSION_RESOURCE_TYPE,
                tier,
                component,
                extensions,
                fn)]
[/#function]

[#function formatLambdaArn lambdaId account={ "Ref" : "AWS::AccountId" }]
    [#return
        formatRegionalArn(
            "lambda",
            getReference(lambdaId))]
[/#function]