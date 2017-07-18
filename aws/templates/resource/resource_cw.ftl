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

[#macro createLogMetric mode id name logGroup filter namespace value]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}" : {
                "Type" : "AWS::Logs::MetricFilter",
                "Properties" : {
                    "FilterPattern" : "${filter}",
                    "LogGroupName" : 
                        [#if logGroup?is_hash]
                            {
                                "Fn::Join" : [
                                    "",
                                    [
                                        "API-Gateway-Execution-Logs_",
                                        { "Ref" : "${logGroup.Api}" },
                                        "/${logGroup.Stage}"
                                    ]
                                ]
                            },
                        [#else]
                            "${logGroup}",
                        [/#if]
                    "MetricTransformations": [
                        {
                            "MetricName": "${name}",
                            "MetricValue": "${value}",
                            "MetricNamespace": "${namespace}"
                        }
                    ]
                }
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
                    "DashboardBody" : [@toJSON body /]
                }
            }
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output id /]
            [#break]

    [/#switch]
[/#macro]


