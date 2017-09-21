[#-- Cloud Watch --]

[#function getCloudWatchLogsProduceStatement ]
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

[#macro cloudWatchLogsProduceStatement ]
    [@policyStatements getCloudWatchLogsProduceStatement() /]
[/#macro]

