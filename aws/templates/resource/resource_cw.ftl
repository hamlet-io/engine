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

