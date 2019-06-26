[#ftl]

[#function lbRegisterTargetPermission ]
    [#return
        [
            getPolicyStatement(
                [
                    "elasticloadbalancing:RegisterTargets",
                    "elasticloadbalancing:DeregisterTargets",
                    "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                    "elasticloadbalancing:DeRegisterInstancesWithLoadBalancer"
                ]
            )
        ]
    ]
[/#function]
