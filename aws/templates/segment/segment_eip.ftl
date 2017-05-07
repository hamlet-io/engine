[#-- EIPs --]
[#if deploymentUnit?contains("eip")]
    [#if jumpServer]
        [#if resourceCount > 0],[/#if]
        [#assign tier = getTier("mgmt")]
        [#assign eipCount = 0]
        [#list zones as zone]
            [#if jumpServerPerAZ || (zones[0].Id == zone.Id)]
                [#if eipCount > 0],[/#if]
                [#assign elasticIPId = formatComponentEIPId(tier, "nat", zone.Id)]
                [#switch segmentListMode]
                    [#case "definition"]
                        "${elasticIPId}": {
                            "Type" : "AWS::EC2::EIP",
                            "Properties" : {
                                "Domain" : "vpc"
                            }
                        }
                        [#break]

                    [#case "outputs"]
                        [@outputIPAddress elasticIPId /],
                        [@outputAllocation elasticIPId /]
                        [#break]

                [/#switch]
                [#assign eipCount += 1]
            [/#if]
        [/#list]
        [#assign resourceCount += 1]
    [/#if]
[/#if]

