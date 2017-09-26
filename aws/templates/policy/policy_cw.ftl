[#-- Cloud Watch --]

[#function cwLogsProducePermission ]
    [#return
        [
            getPolicyStatement(
                [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents",
                    "logs:DescribeLogGroups",
                    "logs:DescribeLogStreams"
                ])
        ]
    ]
[/#function]

