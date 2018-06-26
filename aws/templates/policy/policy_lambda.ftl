[#function lambdaInvokePermission id ]
    [#return
        [
            getPolicyStatement(
                "lambda:InvokeFunction",
                getReference(id, ARN_ATTRIBUTE_TYPE))
        ]
    ]
[/#function]
