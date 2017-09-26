[#-- Lambda --]

[#assign LAMBDA_RESOURCE_TYPE = "lambda" ]
[#assign LAMBDA_FUNCTION_RESOURCE_TYPE = "lambda" ]

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
