[#-- EIPs --]
[#if deploymentUnit?contains("eip")]
    [#if jumpServer]
        [#if resourceCount > 0],[/#if]
        [#assign tier = getTier("mgmt")]
        [#assign eipCount = 0]
        [#list zones as zone]
            [#if jumpServerPerAZ || (zones[0].Id == zone.Id)]
                [#if eipCount > 0],[/#if]
                [#switch segmentListMode]
                    [#case "definition"]
                        "${formatId("eip", tier.Id, "nat", zone.Id)}": {
                            "Type" : "AWS::EC2::EIP",
                            "Properties" : {
                                "Domain" : "vpc"
                            }
                        }
                        [#break]

                    [#case "outputs"]
                        "${formatId("eip", tier.Id, "nat", zone.Id, "ip")}": {
                            "Value" : { "Ref" : "${formatId("eip", tier.Id, "nat", zone.Id)}" }
                        },
                        "${formatId("eip", tier.Id, "nat", zone.Id, "id")}": {
                            "Value" : { "Fn::GetAtt" : ["${formatId("eip", tier.Id, "nat", zone.Id)}", "AllocationId"] }
                        }
                        [#break]

                [/#switch]
                [#assign eipCount += 1]
            [/#if]
        [/#list]
        [#assign resourceCount += 1]
    [/#if]
[/#if]

