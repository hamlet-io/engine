[#-- EIPs --]
[#if deploymentUnit?contains("eip")]
    [#if jumpServer]
        [#assign tier = getTier("mgmt")]
        [#list zones as zone]
            [#if jumpServerPerAZ || (zones[0].Id == zone.Id)]
                [#assign elasticIPId = formatComponentEIPId(tier, "nat", zone.Id)]
                [#switch segmentListMode]
                    [#case "definition"]
                        [@checkIfResourcesCreated /]
                        "${elasticIPId}": {
                            "Type" : "AWS::EC2::EIP",
                            "Properties" : {
                                "Domain" : "vpc"
                            }
                        }
                        [@resourcesCreated /]
                        [#break]

                    [#case "outputs"]
                        [@outputIPAddress elasticIPId /]
                        [@outputAllocation elasticIPId /]
                        [#break]

                [/#switch]
            [/#if]
        [/#list]
    [/#if]
[/#if]

