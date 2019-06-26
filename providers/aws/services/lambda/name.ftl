[#ftl]

[#function formatLambdaName tier component lambda ]
    [#return formatName(
                "lambda",
                formatComponentFullName(
                    tier,
                    component,
                    lambda))]
[/#function]

[#function formatLambdaFunctionName tier component lambda fn ]
    [#return formatComponentFullName(
                tier,
                component,
                lambda,
                fn)]
[/#function]

