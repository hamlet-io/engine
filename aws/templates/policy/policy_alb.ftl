[#function albRegisterTargetPermission ]
    [#return
        [
            getPolicyStatement(
                [
                    "elasticloadbalancing:RegisterTargets",
                    "elasticloadbalancing:DeregisterTargets"
                ]
            )
        ]
    ]
[/#function]
