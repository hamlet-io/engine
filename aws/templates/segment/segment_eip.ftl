[#-- EIPs --]
[#if slice?contains("eip")]
    [#if jumpServer]
        [#if resourceCount > 0],[/#if]
        [#assign tier = getTier("mgmt")]
        [#assign eipCount = 0]
        [#list zones as zone]
            [#if jumpServerPerAZ || (zones[0].Id == zone.Id)]
                [#if eipCount > 0],[/#if]
                [#switch segmentListMode]
                    [#case "definition"]
                        "eipX${tier.Id}XnatX${zone.Id}": {
                            "Type" : "AWS::EC2::EIP",
                            "Properties" : {
                                "Domain" : "vpc"
                            }
                        }
                        [#break]

                    [#case "outputs"]
                        "eipX${tier.Id}XnatX${zone.Id}Xip": {
                            "Value" : { "Ref" : "eipX${tier.Id}XnatX${zone.Id}" }
                        },
                        "eipX${tier.Id}XnatX${zone.Id}Xid": {
                            "Value" : { "Fn::GetAtt" : ["eipX${tier.Id}XnatX${zone.Id}", "AllocationId"] }
                        }
                        [#break]

                [/#switch]
                [#assign eipCount += 1]
            [/#if]
        [/#list]
        [#assign resourceCount += 1]
    [/#if]
[/#if]

