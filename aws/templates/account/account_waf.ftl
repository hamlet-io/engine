[#-- WAF IP setup --]
[#if deploymentUnit?contains("waf") && ipAddressGroupsUsage["waf"]?has_content]
    [#list ipAddressGroupsUsage["waf"]?values as group]
        [#assign ipSetId = formatWAFIPSetId(group)]
        [#assign ipSetName = formatWAFIPSetName(group)]
        [#assign ipRuleId = formatWAFIPSetRuleId(group)]
        [#assign entries = []]
        [#list group.CIDR as CIDRBlock]
            [#if !CIDRBlock?contains("0.0.0.0")]
                [#assign entries += [CIDRBlock]]
            [/#if]
        [/#list]
        [#if entries?has_content]
            [#switch accountListMode]
                [#case "definition"]
                    [@checkIfResourcesCreated /]
                    "${ipSetId}" : {
                        "Type" : "AWS::WAF::IPSet",
                        "Properties" : {
                            "Name": "${ipSetName}",
                            "IPSetDescriptors": [
                                [#list entries as entry]
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
                    [@output ipSetId /]
                    [#break]
            [/#switch]
            [@createWAFRule
                accountListMode,
                ipRuleId,
                ipSetName,
                [
                    {
                        "Id" : ipSetId,
                        "Type" : "IPMatch"
                    }
                ]
            /]
        [/#if]
    [/#list]
[/#if]

