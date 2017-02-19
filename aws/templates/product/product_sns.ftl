[#-- SNS for product --]
[#if slice?contains("sns")]
    [#if sliceCount > 0],[/#if]
    [#switch productListMode]
        [#case "definition"]
            "snsXalerts" : {
                "Type": "AWS::SNS::Topic",
                "Properties" : {
                    "DisplayName" : "${(productName + "-alerts")[0..9]}",
                    "TopicName" : "${productName}-alerts",
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
            "snsXproductXalertsX${regionId?replace("-","")}" : {
                "Value" : { "Ref" : "snsXalerts" }
            }
            [#break]


    [/#switch]
    [#assign sliceCount += 1]
[/#if]

