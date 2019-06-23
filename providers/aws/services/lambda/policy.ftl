[#ftl]

[#function lambdaInvokePermission id ]
    [#return
        [
            getPolicyStatement(
                "lambda:InvokeFunction",
                getReference(id, ARN_ATTRIBUTE_TYPE))
        ]
    ]
[/#function]

[#function lambdaSSMAutomationPermission ]
    [#return
        [
            getPolicyStatement(
                [
                    "lambda:InvokeFunction",
                    "lambda:GetFunction",
                    "lambda:CreateFunction",
                    "lambda:ListFunctions",
                    "lambda:DeleteFunction"
                ]
            )
        ]
    ]
[/#function]

[#function lambdaKinesisPermission id]
    [#return
        [
            getPolicyStatement(
                [
                    "lambda:InvokeFunction",
                    "lambda:GetFunctionConfiguration"
                ],
                getArn(id)
            )
        ]
    ]
[/#function]