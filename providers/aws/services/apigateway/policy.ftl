[#ftl]

[#function apigatewayInvokePermission id stage]
    [#return
        [
            getPolicyStatement(
                "execute-api:Invoke",
                formatInvokeApiGatewayArn(id, stage))
        ]
    ]
[/#function]

