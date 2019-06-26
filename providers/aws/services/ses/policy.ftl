[#ftl]

[#function getSESSendStatement principals="" conditions="" ]
    [#return
        [
            getPolicyStatement(
                [
                    "ses:SendEmail",
                    "ses:SendRawEmail"
                ],
                "*",
                principals,
                conditions)
        ]
    ]
[/#function]