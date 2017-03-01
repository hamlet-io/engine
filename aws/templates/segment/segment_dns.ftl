[#-- Private DNS zone --]
[#if deploymentUnit?contains("dns")]
    [#if resourceCount > 0],[/#if]
    [#switch segmentListMode]
        [#case "definition"]
            "dns" : {
                "Type" : "AWS::Route53::HostedZone",
                "Properties" : {
                    "HostedZoneConfig" : {
                        "Comment" : "${formatName(productName, segmentName)}"
                    },
                    "HostedZoneTags" : [ 
                        { "Key" : "cot:request", "Value" : "${requestReference}" },
                        { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                        { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                        { "Key" : "cot:account", "Value" : "${accountId}" },
                        { "Key" : "cot:product", "Value" : "${productId}" },
                        { "Key" : "cot:segment", "Value" : "${segmentId}" },
                        { "Key" : "cot:environment", "Value" : "${environmentId}" },
                        { "Key" : "cot:category", "Value" : "${categoryId}" }
                    ],
                    "Name" : "${segmentName}.${productName}.internal",
                    "VPCs" : [                
                        { "VPCId" : "${getKey("vpc","segment","vpc")}", "VPCRegion" : "${regionId}" }
                    ]
                }
            }
            [#break]

        [#case "outputs"]
            "${formatId("dns", "segment", "dns")}" : {
                "Value" : { "Ref" : "dns" }
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]

