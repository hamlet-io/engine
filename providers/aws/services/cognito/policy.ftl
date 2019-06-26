[#ftl]

[#function getUserPoolUnAuthPolicy ]
    [#return
        [
            getPolicyStatement(
                    [
                        "mobileanalytics:PutEvents",
                        "cognito-sync:*"
                    ]
            )
        ]
    ]
[/#function]

[#function getUserPoolAuthPolicy]
    [#return
        [
            getPolicyStatement(
                [
                    "mobileanalytics:PutEvents",
                    "cognito-sync:*",
                    "cognito-identity:*"
                ]
            )
        ]
    ]
[/#function]