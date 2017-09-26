[#-- Lambda --]

[#function formatLambdaId tier component extensions...]
    [#return formatComponentResourceId(
                "lambda",
                tier,
                component,
                extensions)]
[/#function]

[#function formatLambdaFunctionId tier component fn extensions...]
    [#return formatComponentResourceId(
                "lambda",
                tier,
                component,
                extensions,
                fn)]
[/#function]
