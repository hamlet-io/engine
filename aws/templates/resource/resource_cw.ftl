[#-- CloudWatch --]

[#assign LOG_GROUP_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : { 
            "Attribute" : "Arn"
        }
    }
]
[#assign outputMappings +=
    {
        LOG_GROUP_RESOURCE_TYPE : LOG_GROUP_OUTPUT_MAPPINGS
    }
]

[#macro createLogGroup mode id name retention=0]
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::Logs::LogGroup"
        properties=
            {
                "LogGroupName" : name
            } +
            (retention > 0)?then(
                {
                    "RetentionInDays" : retention
                },
                (operationsExpiration?is_number)?then(
                    {
                        "RetentionInDays" : operationsExpiration
                    },
                    {}
                )
            )
        outputs=LOG_GROUP_OUTPUT_MAPPINGS
    /]
[/#macro]

[#macro createLogMetric mode id name logGroup filter namespace value dependencies=""]
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::Logs::MetricFilter"
        properties=
            {
                "FilterPattern" : filter,
                "LogGroupName" : logGroup,
                "MetricTransformations": [
                    {
                        "MetricName": name,
                        "MetricValue": value,
                        "MetricNamespace": namespace
                    }
                ]
            }
        dependencies=dependencies
    /]
[/#macro]

[#macro createDashboard mode id name body ]
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::CloudWatch::Dashboard"
        properties=
            {
                "DashboardName" : name,
                "DashboardBody" : getJSON(body)?json_string
            }
    /]
[/#macro]

[#macro createCountAlarm mode id name
            actions
            metric
            namespace
            dimensions=[]
            description=""
            threshold=1
            statistic="Sum"
            evaluationPeriods=1
            period=300
            operator="GreaterThanOrEqualToThreshold"
            missingData="notBreaching"
            reportOK=false
            dependencies=""]
    [@cfTemplate
        mode=mode
        id=id
        type="AWS::CloudWatch::Alarm"
        properties=
            {
                "ActionsEnabled" : true,
                "AlarmActions" : actions,
                "AlarmDescription" : description?has_content?then(description,name),
                "AlarmName" : name,
                "ComparisonOperator" : operator,
                "EvaluationPeriods" : evaluationPeriods,
                "MetricName" : metric,
                "Namespace" : namespace,
                "Period" : period,
                "Statistic" : statistic,
                "Threshold" : threshold,
                "TreatMissingData" : missingData,
                "Unit" : "Count"
            } +
            dimensions?has_content?then(
                {
                    "Dimensions" : dimensions
                },
                {}
            ) +
            reportOK?then(
                {
                    "OKActions" : actions
                },
                {}
            )
        dependencies=dependencies
    /]
[/#macro]

