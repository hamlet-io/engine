[#ftl]

[#function cwLogsProducePermission logGroupName="" ]
    [#local logGroupArn = logGroupName?has_content?then(
                    formatRegionalArn(
                            "logs",
                            "log-group:" + logGroupName + "*"),
                    "*")]
    [#return
        [
            getPolicyStatement(
                [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents",
                    "logs:DescribeLogGroups",
                    "logs:DescribeLogStreams"
                ],
                logGroupArn)
        ]
    ]
[/#function]

[#function cwLogsConfigurePermission ]
    [#return
        [
            getPolicyStatement(
                [
                    "logs:PutMetricFilter",
                    "logs:PutRetentionPolicy"
                ]
            )
        ]
    ]
[/#function]
