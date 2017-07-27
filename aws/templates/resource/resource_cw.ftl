[#-- CloudWatch --]

[#macro createLogGroup mode id name retention=0]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}" : {
                "Type" : "AWS::Logs::LogGroup",
                "Properties" : {
                    "LogGroupName" : "${name}"
                    [#if retention > 0]
                        ,"RetentionInDays" : ${retention}
                    [#else]
                        [#if operationsExpiration?is_number]
                            ,"RetentionInDays" : ${operationsExpiration}
                        [/#if]
                    [/#if]
                }
            }
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output id /]
            [@outputArn id /]
            [#break]

    [/#switch]
[/#macro]

[#macro createLogMetric mode id name logGroup filter namespace value dependencies]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}" : {
                "Type" : "AWS::Logs::MetricFilter",
                "Properties" : {
                    "FilterPattern" : "${filter}",
                    "LogGroupName" : [@toJSON logGroup /],
                    "MetricTransformations": [
                        {
                            "MetricName": "${name}",
                            "MetricValue": "${value}",
                            "MetricNamespace": "${namespace}"
                        }
                    ]
                }
                [#if dependencies?has_content]
                    ,"DependsOn" : [
                        [#list dependencies as dependency]
                            "${dependency}"
                            [#sep],[/#sep]
                        [/#list]
                    ]
                [/#if]
            }
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output id /]
            [#break]

    [/#switch]
[/#macro]

[#macro createDashboard mode id name body ]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}" : {
                "Type" : "AWS::CloudWatch::Dashboard",
                "Properties" : {
                    "DashboardName" : "${name}",
                    "DashboardBody" : "[@toJSON body true /]"
                }
            }
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output id /]
            [#break]

    [/#switch]
[/#macro]

[#macro createCountAlarm mode id name
            actions
            metric namespace dimensions=[]
            description=""
            threshold=1
            statistic="Sum"
            evaluationPeriods=1
            period=300
            operator="GreaterThanOrEqualToThreshold"
            missingData="notBreaching"
            reportOK=false
            dependencies=""]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}" : {
                "Type" : "AWS::CloudWatch::Alarm",
                "Properties" : {
                    "ActionsEnabled" : true,
                    "AlarmActions" : [
                        [#list actions as action]
                            [@toJSON action /]
                            [#sep],[/#sep]
                        [/#list]
                    ],
                    "AlarmDescription" : "${description?has_content?then(description,name)}",
                    "AlarmName" : "${name}",
                    "ComparisonOperator" : "${operator}",
                    [#if dimensions?has_content]
                        "Dimensions" : [
                            [#list dimensions as dimension]
                                {
                                    "Name" : "${dimension.Name}",
                                    "Value" : [@toJSON dimension.Value /]
                                }
                                [#sep],[/#sep]
                            [/#list]
                        ],
                    [/#if]
                    "EvaluationPeriods" : ${evaluationPeriods},
                    "MetricName" : "${metric}",
                    "Namespace" : "${namespace}",
                    [#if reportOK]
                        "OKActions" : [
                            [#list actions as action]
                                "${action}"
                                [#sep],[/#sep]
                            [/#list]
                        ]
                    [/#if]
                    "Period" : ${period},
                    "Statistic" : "${statistic}",
                    "Threshold" : ${threshold},
                    "TreatMissingData" : "${missingData}",
                    "Unit" : "Count"
                }
                [#if dependencies?has_content]
                    ,"DependsOn" : [
                        [#list dependencies as dependency]
                            "${dependency}"
                            [#sep],[/#sep]
                        [/#list]
                    ]
                [/#if]
            }
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output id /]
            [#break]

    [/#switch]
[/#macro]

