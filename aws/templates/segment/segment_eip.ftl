[#-- EIPs --]
[#if deploymentUnit?contains("eip")]
    [#if jumpServer]
        [#if resourceCount > 0],[/#if]
        [#assign tier = getTier("mgmt")]
        [#assign eipCount = 0]
        [#list zones as zone]
            [#if jumpServerPerAZ || (zones[0].Id == zone.Id)]
                [#if eipCount > 0],[/#if]
                [#assign elasticIPResourceId = formatComponentEIPResourceId(tier, "nat", zone.Id)]
                [#switch segmentListMode]
                    [#case "definition"]
                        "${elasticIPResourceId}": {
                            "Type" : "AWS::EC2::EIP",
                            "Properties" : {
                                "Domain" : "vpc"
                            }
                        }
                        [#break]

                    [#case "outputs"]
                        "${formatResourceIPAddressAttributeId(elasticIPResourceId)}": {
                            "Value" : { "Ref" : "${elasticIPResourceId}" }
                        },
                        "${formatResourceAllocationIdAttributeId(elasticIPResourceId)}": {
                            "Value" : { "Fn::GetAtt" : ["${elasticIPResourceId}", "AllocationId"] }
                        }
                        [#break]

                [/#switch]
                [#assign eipCount += 1]
            [/#if]
        [/#list]
        [#assign resourceCount += 1]
    [/#if]
[/#if]

