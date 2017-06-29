[#-- Cloud Watch --]

[#macro cloudWatchLogsProduceStatement ]
    [@policyStatement
        [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams"
        ]
    /]
[/#macro]
