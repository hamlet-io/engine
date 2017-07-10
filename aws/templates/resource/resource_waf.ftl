[#-- Web Application Firewall --]

[#macro createWAFIPSet mode id name cidr]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}" : {
                "Type" : "AWS::WAF::IPSet",
                "Properties" : {
                    "Name": "${name}",
                    "IPSetDescriptors": [
                        [#list cidr as entry]
                            {
                                "Type" : "IPV4",
                                "Value" : "${entry}"
                            }
                            [#sep],[/#sep]
                        [/#list]
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

[#macro createWAFRule mode id name metric conditions]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}" : {
                "Type" : "AWS::WAF::Rule",
                "Properties" : {
                    "MetricName" : "${metric?replace("-","X")}",
                    "Name": "${name}",
                    "Predicates" : [
                        [#list conditions as condition]
                            {
                              "DataId" : [@createReference condition.Id /],
                              "Negated" : ${(condition.Negate?has_content &&
                                            condition.Negate)?c},
                              "Type" : "${condition.Type}"
                            }
                            [#sep],[/#sep]
                        [/#list]
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

[#macro createWAFAcl mode id name metric default rules]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}" : {
                "Type" : "AWS::WAF::WebACL",
                "Properties" : {
                    "DefaultAction" : {
                        "Type" : "${default}"
                    },
                    "MetricName" : "${metric?replace("-","X")}",
                    "Name": "${name}",
                    "Rules" : [
                        [#list rules as rule]
                            {
                              "RuleId" : [@createReference rule.Id /],
                              "Priority" : ${rule?counter?c},
                              "Action" : {
                                  "Type" : "${rule.Action}"
                              }
                            }
                            [#sep],[/#sep]
                        [/#list]
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

