[#function iamPassRolePermission role ]
    [#return
        [
            getPolicyStatement(
                [
                    "iam:GetRole",
                    "iam:PassRole"
                ],
                role
            )
        ]
    ]
[/#function]

