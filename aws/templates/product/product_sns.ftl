[#-- SNS for product --]
[#if deploymentUnit?contains("sns")]
    [#if resourceCount > 0],[/#if]
    [#switch productListMode]
        [#case "definition"]
            "${formatId("sns", "alerts")}" : {
                "Type": "AWS::SNS::Topic",
                "Properties" : {
                    "DisplayName" : "${(formatName(productName, "alerts"))[0..9]}",
                    "TopicName" : "${formatName(productName, "alerts")}",
                    "Subscription" : [
                        {
                            "Endpoint" : "alerts@${productDomain}",
                            "Protocol" : "email"
                        }
                    ]
                }
            }
            [#break]

        [#case "outputs"]
            "${formatId("sns", "product", "alerts", regionId?replace("-",""))}" : {
                "Value" : { "Ref" : "${formatId("sns", "alerts")}" }
            }
            [#break]


    [/#switch]
    [#assign resourceCount += 1]
[/#if]

